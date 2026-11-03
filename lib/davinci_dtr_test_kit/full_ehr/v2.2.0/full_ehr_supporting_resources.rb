require 'base64'
require_relative '../fixture_loader'
require_relative '../../cross_suite/canonical_matching'
require_relative '../../cross_suite/inferno_control_extensions'

module DaVinciDTRTestKit
  module MockPayer
    # Finds the CQL Libraries and ValueSets that Inferno adds to $questionnaire-package and
    # $next-question responses. Candidate resources come from the Bundles configured by the
    # library_bundle_* and value_set_bundle_* options (see DTRFullEHRV220AbstractAdaptive).
    #
    # A resource is added when it is referenced by canonical from
    # - a cqf-library extension on a Questionnaire or item,
    # - an item's answerValueSet,
    # - an include-resource extension on a Questionnaire or item, or
    # - a depends-on relatedArtifact or an ELM include of a Library that is itself added.
    # References that can't be found in the Bundles (e.g., FHIR-ModelInfo, which DTR clients
    # provide themselves) are skipped. ValueSets keep their expansion only when they have an
    # include-value-set-expanded extension set to true, so that clients otherwise need $expand.
    #
    # Including classes must define `input_title(input_name)`.
    module FullEHRV220SupportingResources
      include DaVinciDTRTestKit::CanonicalMatching

      CQF_LIBRARY_URL = 'http://hl7.org/fhir/StructureDefinition/cqf-library'.freeze
      INCLUDE_RESOURCE_URL = InfernoControlExtensions::INCLUDE_RESOURCE_URL
      SUPPORTING_RESOURCE_KINDS = [:library, :value_set].freeze

      # ***********************************************************************
      # Canonical references
      # ***********************************************************************

      # Canonicals referenced by the Questionnaire or item itself, not by its child items.
      def directly_referenced_canonicals(questionnaire_or_item)
        canonicals = questionnaire_or_item.extension
          .select { |ext| [CQF_LIBRARY_URL, INCLUDE_RESOURCE_URL].include?(ext.url) }
          .map(&:valueCanonical)
        canonicals << questionnaire_or_item.answerValueSet if questionnaire_or_item.respond_to?(:answerValueSet)
        canonicals.select(&:present?)
      end

      def referenced_canonicals(questionnaire)
        directly_referenced_canonicals(questionnaire) +
          all_questionnaire_items(questionnaire.item).flat_map { |item| directly_referenced_canonicals(item) }
      end

      def all_questionnaire_items(items)
        items.flat_map { |item| [item] + all_questionnaire_items(item.item) }
      end

      # ***********************************************************************
      # Resolution
      # ***********************************************************************

      # Returns the configured Libraries and ValueSets needed to satisfy the given canonicals,
      # including Library dependencies, leaving out any that match a resource in `exclude`
      # (the dependencies of excluded Libraries are still resolved). Raises MockPayer::ParseError
      # if a Bundle provided in an input can't be loaded.
      def resolve_supporting_resources(canonicals, exclude: [])
        resolved = []
        visited = Set.new
        pending = canonicals.dup
        until pending.empty?
          canonical = pending.shift
          next unless visited.add?(canonical)

          pending.concat(resolve_canonical(canonical, exclude, resolved))
        end
        resolved
      end

      # Adds the resource matching the canonical to `resolved` unless it is already there or in
      # `exclude`, and returns the canonicals it depends on.
      def resolve_canonical(canonical, exclude, resolved)
        match = find_by_canonical(exclude + resolved, canonical)
        if match.nil?
          match = find_by_canonical(supporting_resources, canonical)
          return [] if match.nil?

          resolved << response_copy(match)
        end
        library_dependencies(match)
      end

      # The configured resource as it should appear in a response. ValueSets are copied so that
      # removing the expansion and control extensions doesn't change the configured Bundle.
      def response_copy(resource)
        return resource unless resource.is_a?(FHIR::ValueSet)

        copy = FHIR::ValueSet.new(resource.to_hash)
        copy.expansion = nil unless include_value_set_expansion?(resource)
        copy.extension.reject! { |extension| InfernoControlExtensions::ALL_URLS.include?(extension.url) }
        copy
      end

      def include_value_set_expansion?(value_set)
        InfernoControlExtensions.find_extension(value_set, InfernoControlExtensions::INCLUDE_VALUE_SET_EXPANDED_URL)
          &.valueBoolean == true
      end

      def find_by_canonical(resources, canonical)
        resources.find { |resource| canonical_matches?(resource, canonical) }
      end

      def library_dependencies(resource)
        return [] unless resource.is_a?(FHIR::Library)

        (related_artifact_dependencies(resource) + elm_include_dependencies(resource)).uniq
      end

      def related_artifact_dependencies(library)
        library.relatedArtifact.select { |artifact| artifact.type == 'depends-on' }.map(&:resource).compact
      end

      # Authoring tools such as MADiE leave libraries that are used only within functions out of
      # relatedArtifact, so the includes in the Library's ELM are followed too.
      def elm_include_dependencies(library)
        @elm_include_dependencies ||= {}.compare_by_identity
        @elm_include_dependencies[library] ||=
          elm_include_definitions(library).filter_map { |include| elm_include_canonical(include) }
      end

      # The include definitions in the Library's ELM. ELM that doesn't have the expected shape is
      # ignored, as is ELM that isn't valid JSON.
      def elm_include_definitions(library)
        includes = elm_library(library)&.[]('includes')
        definitions = includes['def'] if includes.is_a?(Hash)
        definitions.is_a?(Array) ? definitions.grep(Hash) : []
      end

      # An ELM include's path is `{namespace uri}/{library name}`, and by the CQL on FHIR convention
      # the Library's canonical url is `{namespace uri}/Library/{library name}`. Includes without a
      # namespace can't be mapped to a url.
      def elm_include_canonical(include)
        namespace, _separator, name = include['path'].to_s.rpartition('/')
        return if namespace.blank? || name.blank?

        url = "#{namespace}/Library/#{name}"
        include['version'].present? ? "#{url}|#{include['version']}" : url
      end

      def elm_library(library)
        elm_content = library.content.find do |content|
          content.contentType.to_s.start_with?('application/elm+json') && content.data.present?
        end
        return if elm_content.nil?

        elm = JSON.parse(Base64.decode64(elm_content.data))
        elm['library'] if elm.is_a?(Hash) && elm['library'].is_a?(Hash)
      rescue JSON::ParserError
        nil
      end

      # ***********************************************************************
      # Bundle sources
      # ***********************************************************************

      def supporting_resources
        @supporting_resources ||= load_supporting_resources
      end

      def load_supporting_resources
        resources = SUPPORTING_RESOURCE_KINDS.filter_map { |kind| supporting_resource_bundle(kind) }
          .flat_map { |bundle| bundle.entry.map(&:resource) }
        resources.grep(FHIR::Library) + resources.grep(FHIR::ValueSet)
      end

      def supporting_resource_bundle(kind)
        fixture_path = test.config.options[:"#{kind}_bundle_fixture"]
        input_name = test.config.options[:"#{kind}_bundle_input"]

        if fixture_path.present?
          supporting_resource_bundle_from_fixture(fixture_path)
        elsif input_name.present?
          supporting_resource_bundle_from_input(input_name)
        end
      end

      def supporting_resource_bundle_from_fixture(fixture_path)
        fixture = FixtureLoader.instance[fixture_path]
        unless fixture.is_a?(FHIR::Bundle)
          raise Inferno::Exceptions::TestSuiteImplementationException.new(
            'dtr supporting resource Bundle fixture',
            "Invalid supporting resource Bundle fixture #{fixture_path}: " \
            "Expected Bundle, got '#{fixture.resourceType}'."
          )
        end
        fixture
      end

      # The input is optional: no value means there are no supporting resources to add.
      def supporting_resource_bundle_from_input(input_name)
        value = JSON.parse(result.input_json)
          .find { |input| input['name'] == input_name }
          &.dig('value')
        return if value.blank?

        title = input_title(input_name)
        parsed = parse_fhir_object(value, entity: "Input #{title}")
        return parsed if parsed.is_a?(FHIR::Bundle)

        raise MockPayer::ParseError,
              "Invalid supporting resource Bundle in input '#{title}': Expected Bundle, got '#{parsed.resourceType}'."
      end
    end
  end
end
