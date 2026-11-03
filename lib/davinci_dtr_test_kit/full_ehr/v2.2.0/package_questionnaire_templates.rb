require_relative '../../cross_suite/canonical_matching'
require_relative '../../cross_suite/inferno_control_extensions'

module DaVinciDTRTestKit
  # Builds Questionnaires in $questionnaire-package responses from $next-question templates so
  # that the two don't have to be kept in sync by hand.
  #
  # A Questionnaire in a package bundle, or contained in a QuestionnaireResponse in a package
  # bundle, that has a use-next-question-questionnaire-template extension is a placeholder.
  # Inferno replaces it with the $next-question template Questionnaire whose url (and version,
  # if given) matches the extension's valueCanonical, keeping only the items marked with an
  # include-in-package extension and the items that contain them (a marked item with no marked
  # children keeps all of them). Elements set on the placeholder, such as `id`, take precedence
  # over the template's, and the placeholder's other extensions are added to the template's,
  # except for exact duplicates.
  #
  # Shared by the $questionnaire-package endpoint and the interaction wait test so that tester
  # templates can be checked before the interaction starts, and by the $next-question endpoint to
  # find the Questionnaires a package delivered. Including classes that expand placeholders must
  # define `next_question_templates`, returning the available $next-question template Questionnaires.
  module PackageQuestionnaireTemplates
    include CanonicalMatching

    class MissingTemplateError < StandardError; end

    def package_bundles(parameters)
      parameters.parameter.select { |param| param.name == 'packagebundle' }.map(&:resource).grep(FHIR::Bundle)
    end

    # Questionnaires in the bundle, including those contained in its QuestionnaireResponses.
    def package_questionnaires(bundle)
      resources = bundle.entry.map(&:resource)
      resources.grep(FHIR::Questionnaire) +
        resources.grep(FHIR::QuestionnaireResponse).flat_map { |response| response.contained.grep(FHIR::Questionnaire) }
    end

    def template_placeholder_canonicals(parameters)
      package_bundles(parameters).flat_map { |bundle| package_questionnaires(bundle) }
        .filter_map { |questionnaire| template_placeholder_canonical(questionnaire) }
    end

    def template_placeholder_canonical(questionnaire)
      InfernoControlExtensions.find_extension(questionnaire, InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL)
        &.valueCanonical
    end

    def find_next_question_template(canonical)
      next_question_templates.find { |template| canonical_matches?(template, canonical) }
    end

    # Replaces the placeholders in the package bundles of `parameters`, which is modified.
    # Raises MissingTemplateError when no template matches a placeholder.
    def expand_template_placeholders(parameters)
      package_bundles(parameters).each do |bundle|
        bundle.entry.each do |entry|
          if entry.resource.is_a?(FHIR::QuestionnaireResponse)
            entry.resource.contained.map! { |resource| expand_if_placeholder(resource) }
          else
            entry.resource = expand_if_placeholder(entry.resource)
          end
        end
      end
    end

    def expand_if_placeholder(resource)
      return resource unless resource.is_a?(FHIR::Questionnaire)

      canonical = template_placeholder_canonical(resource)
      return resource if canonical.blank?

      template = find_next_question_template(canonical)
      raise MissingTemplateError, "No $next-question template Questionnaire matches #{canonical}." if template.nil?

      expanded_questionnaire(resource, template)
    end

    def expanded_questionnaire(placeholder, template)
      placeholder_hash = placeholder.to_hash
      placeholder_extensions = (placeholder_hash.delete('extension') || []).reject do |extension|
        extension['url'] == InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL
      end
      template_hash = template.to_hash

      expanded = template_hash.except('item').merge(placeholder_hash.except('item'))
      # Placeholders adapted from an existing package may repeat the template's extensions, such as
      # questionnaireAdaptive, which can appear only once.
      extensions = ((template_hash['extension'] || []) + placeholder_extensions).uniq
      expanded['extension'] = extensions if extensions.present?
      items = package_items(template_hash['item'] || [])
      expanded['item'] = items if items.present?
      FHIR::Questionnaire.new(expanded)
    end

    # Items marked include-in-package, along with the items that contain them. A marked item with no
    # marked children keeps all of its children, so that a marked group is never left empty.
    def package_items(items)
      items.filter_map do |item|
        children = package_items(item['item'] || [])
        next unless include_in_package?(item) || children.present?

        children.present? ? item.merge('item' => children) : item
      end
    end

    def include_in_package?(item_hash)
      (item_hash['extension'] || []).any? do |extension|
        extension['url'] == InfernoControlExtensions::INCLUDE_IN_PACKAGE_URL && extension['valueBoolean'] == true
      end
    end
  end
end
