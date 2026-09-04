# NOTE: this was copied from 2.0.1 'cql_test', and is in the process of being updated
module DaVinciDTRTestKit
  module QuestionnaireOperationValidation
    QUESTIONNAIRE_PACKAGE_BUNDLE_PROFILE = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.2.0'.freeze
    QUESTIONNAIRE_PACKAGE_PARAMETER_PROFILE = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.2.0'.freeze

    def extension_presence
      @extension_presence ||= { 'found_min_launch_context' => false, 'found_min_variable' => false,
                                'found_min_pop_context' => false, 'found_min_init_expression' => false,
                                'found_min_candidate_expression' => false, 'found_min_context_expression' => false,
                                'found_min_cqf_lib' => false }
    end

    # def cql_presence
    #   @cql_presence ||= { 'launch_context' => true, 'variable' => true,
    #                       'pop_context' => true, 'init_expression' => true,
    #                       'candidate_expression' => true, 'context_expression' => true }
    # end

    # def cqf_reference_libraries
    #   scratch[:cqf_reference_libraries] ||= Set.new
    # end

    def library_canonicals
      @library_canonicals ||= Set.new
    end

    def library_names
      @library_names ||= Set.new
    end

    def reset_library_tracking
      @library_canonicals = Set.new
      @library_names = Set.new
    end

    # def found_questionnaire
    #   @found_questionnaire ||= false
    # end

    # def found_duplicate_library_name
    #   @found_duplicate_library_name ||= false
    # end

    # def found_non_cql_elm_library
    #   @found_non_cql_elm_library ||= false
    # end

    # def found_non_cql_expression
    #   @found_non_cql_expression ||= false
    # end

    # def verify_questionnaire_extensions(questionnaires)
    #   assert questionnaires&.any? && questionnaires.all?(FHIR::Questionnaire), 'No questionnaires found.'
    #   questionnaires.each_with_index { |q, q_index| check_questionnaire_extensions(q, q_index) }
    #   check_library_references
    #   assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
    #   assert cql_presence['variable'], 'Variable expression logic not written in CQL.'
    #   assert cql_presence['launch_context'], 'Launch context expression logic not written in CQL.'
    #   assert cql_presence['pop_context'], 'Population context expression logic not written in CQL.'
    # end

    # def check_questionnaire_extensions(questionnaire, q_index)
    #   # are extensions present in this questionnaire?
    #   found_launch_context = found_variable = found_pop_context = found_cqf_lib = false
    #   cqf_count = total_cqf_libs(questionnaire.extension)
    #   misformatted_expressions = []
    #   questionnaire.extension.each_with_index do |extension, index|
    #     if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext'
    #       found_launch_context = true
    #       extension_presence['found_min_launch_context'] = true
    #       check_for_cql(extension, 'launch_context', index, q_index, extension.url)
    #       misformatted_expressions << check_expression_format(extension, index)
    #     end
    #     if extension.url == 'http://hl7.org/fhir/StructureDefinition/variable'
    #       found_variable = true
    #       extension_presence['found_min_variable'] = true
    #       check_for_cql(extension, 'variable', index, q_index, extension.url)
    #       misformatted_expressions << check_expression_format(extension, index)
    #     end
    #     if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext'
    #       found_pop_context = true
    #       extension_presence['found_min_pop_context'] = true
    #       check_for_cql(extension, 'pop_context', index, q_index, extension.url)
    #       misformatted_expressions << check_expression_format(extension, index)
    #     end
    #     next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

    #     cqf_reference_libraries.add(extension.valueCanonical)
    #     found_cqf_lib = true
    #     extension_presence['found_min_cqf_lib'] = true

    #     check_for_cql(extension, '', index, q_index, extension.url)
    #   end
    #   add_launch_context_messages(found_launch_context, found_variable, found_pop_context, found_cqf_lib, q_index)
    #   return if cqf_count < 1

    #   add_formatting_messages(misformatted_expressions, q_index)
    #   assert misformatted_expressions.compact.empty?, 'Expression in questionnaire misformatted.'
    # end

    # def verify_questionnaire_items(questionnaires, final_cql_test: false)
    #   assert questionnaires&.any? && questionnaires.all?(FHIR::Questionnaire), 'No questionnaires found.'
    #   questionnaires.each_with_index { |q, q_index| check_questionnaire_items(q, q_index) }

    #   begin
    #     assert !found_non_cql_expression, 'Found non-cql expression.'
    #     assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
    #     assert cql_presence['init_expression'], 'Initial expression logic not written in CQL.'
    #     assert cql_presence['candidate_expression'], 'Candidate expression logic not written in CQL.'
    #     assert cql_presence['context_expression'], 'Context expression logic not written in CQL.'
    #   ensure
    #     reset_cql_tests if final_cql_test
    #   end
    # end

    # def add_launch_context_messages(found_launch_context, found_variable, found_pop_context, found_cqf_lib, q_index)
    #   unless found_launch_context
    #     messages << { type: 'info',
    #                   message: format_markdown("[questionnaire #{q_index + 1}] included no launch context.") }
    #   end
    #   unless found_variable
    #     messages << { type: 'info',
    #                   message: format_markdown("[questionnaire #{q_index + 1}]
    #                    included no variable to query for additional data.") }
    #   end
    #   unless found_pop_context
    #     messages << { type: 'info',
    #                   message: format_markdown("[questionnaire #{q_index + 1}]
    #                    included no item population context.") }
    #   end
    #   return if found_cqf_lib

    #   messages << { type: 'info',
    #                 message: format_markdown("[questionnaire #{q_index + 1}]
    #                   included no cqf library.") }
    # end

    # def add_formatting_messages(misformatted_expressions, q_index)
    #   misformatted_expressions.compact.each do |idx|
    #     messages << { type: 'info',
    #                   message: format_markdown("[expression #{idx + 1}] in [questionnaire #{q_index + 1}]
    #                   does not begin with a reference to an included library name.") }
    #   end
    # end

    # def total_cqf_libs(extensions)
    #   cqf_count = 0
    #   extensions.each do |extension|
    #     next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

    #     cqf_count += 1
    #   end
    #   cqf_count
    # end

    # def add_item_messages(found_item_expressions, q_index)
    #   unless found_item_expressions['found_candidate_expression']
    #     messages << { type: 'info',
    #                   message: format_markdown("[questionnaire #{q_index + 1}] included no candidate expression.") }
    #   end
    #   unless found_item_expressions['found_init_expression']
    #     messages << { type: 'info',
    #                   message: format_markdown("[questionnaire #{q_index + 1}] included no initial expression.") }
    #   end
    #   return if found_item_expressions['found_context_expression']

    #   messages << { type: 'info',
    #                 message: format_markdown("[questionnaire #{q_index + 1}] included no context expression.") }
    # end

    # def check_questionnaire_items(questionnaire, q_index)
    #   # are expressions present in this questionnaire?
    #   found_item_expressions = { 'found_init_expression' => false,
    #                              'found_candidate_expression' => false,
    #                              'found_context_expression' => false }
    #   cqf_count = total_cqf_libs(questionnaire.extension)
    #   misformatted_expressions = []

    #   # check questionnaire items
    #   questionnaire.item.each_with_index do |item, index|
    #     misformatted_expressions.concat(check_nested_items(item, index, q_index, found_item_expressions, item.linkId))
    #     # check extensions on items
    #     item.extension.each do |item_ext|
    #       misformatted_expressions << check_item_extension(item_ext,
    #                                                        index, q_index, found_item_expressions, item.linkId)
    #     end
    #   end
    #   add_item_messages(found_item_expressions, q_index)
    #   # only care about formatting when there are multiple cqf libs
    #   return if cqf_count < 1

    #   misformatted_expressions.compact.to_set.each do |idx|
    #     messages << { type: 'info',
    #                   message: format_markdown("[item #{idx + 1}] in [questionnaire #{q_index + 1}]
    #                   contains expression that does not begin with a reference to an included library name.") }
    #   end
    #   assert misformatted_expressions.compact.to_set.empty?, 'Expression in questionnaire misformatted.'
    # end

    def check_libraries(parameters, request_index)
      questionnaire_bundles = extract_questionnaire_bundles(parameters)

      questionnaire_bundles.each do |bundle|
        reset_library_tracking

        libraries = extract_libraries_from_bundles([bundle])

        questionnaires = extract_questionnaires_from_bundles([bundle])

        referenced_libraries =
          Set.new(
            questionnaires
              .flat_map { |questionnaire| referenced_library_canonicals(questionnaire) }
          )

        libraries.each do |library|
          library_canonicals.add(library_canonical(library)) unless library.url.nil?

          referenced_libraries.merge(depends_on_library_canonicals(library))

          evaluate_library(library, request_index)

          next if library_names.add?(library.name)

          add_message(
            'error',
            "Request #{request_index}: Bundle contains multiple libraries named '#{library.name}'"
          )
        end

        check_referenced_libraries(referenced_libraries, library_canonicals, request_index)
      end
    end

    def library_canonical(library)
      library_version_string = library.version.present? ? "|#{library.version}" : ''

      "#{library.url}#{library_version_string}"
    end

    def evaluate_library(library, request_index)
      unless library_contains_cql?(library)
        add_message(
          'error',
          "Request #{request_index}: Library `#{library.url}` does not include CQL."
        )
      end

      unless library_contains_elm?(library) # rubocop:disable Style/GuardClause
        add_message(
          'error',
          "Request #{request_index}: Library `#{library.url}` does not include ELM."
        )
      end
    end

    def library_contains_cql?(library)
      library
        .content
        .any? { |content| content.data.present? && content.contentType == 'text/cql' }
    end

    def library_contains_elm?(library)
      library
        .content
        .any? { |content| content.data.present? && content.contentType == 'application/elm+json' }
    end

    def referenced_library_canonicals(questionnaire)
      questionnaire
        .extension
        .select { |extension| extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library' }
        .map(&:valueCanonical)
    end

    def depends_on_library_canonicals(library)
      library.relatedArtifact.filter_map do |related_artifact|
        related_artifact.resource if related_artifact.type == 'depends-on'
      end
    end

    def check_referenced_libraries(referenced_libraries, found_libraries, request_index)
      unversioned_library_references = referenced_libraries.select { |library| library.exclude? '|' }

      if unversioned_library_references.present?
        unversioned_library_string =
          unversioned_library_references
            .map { |reference| "`#{reference}`" }
            .join(', ')

        add_message(
          'error',
          "The Bundle included the following unversioned library references: #{unversioned_library_string}"
        )
      end

      referenced_libraries.reject! { |library| library.exclude? '|' }

      missing_libraries = referenced_libraries - found_libraries

      return if missing_libraries.blank?

      missing_library_string = missing_libraries.map { |url| "`#{url}`" }.join(', ')

      add_message(
        'error',
        "Request #{request_index}: The following libraries are referenced but not included in the Bundle: " \
        "#{missing_library_string}"
      )
    end

    # def check_item_extension(item_ext, index, q_index, found_item_expressions, link_id)
    #   if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
    #     found_item_expressions['found_candidate_expression'] = true
    #     extension_presence['found_min_candidate_expression'] = true
    #     check_for_cql(item_ext, 'candidate_expression', index, q_index, item_ext.url, link_id)
    #     return check_expression_format(item_ext, index)
    #   end
    #   if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
    #     found_item_expressions['found_init_expression'] = true
    #     extension_presence['found_min_init_expression'] = true
    #     check_for_cql(item_ext, 'init_expression', index, q_index, item_ext.url, link_id)
    #     return check_expression_format(item_ext, index)
    #   end
    #   if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression'
    #     found_item_expressions['found_context_expression'] = true
    #     extension_presence['found_min_context_expression'] = true
    #     check_for_cql(item_ext, 'context_expression', index, q_index, item_ext.url, link_id)
    #     return check_expression_format(item_ext, index)
    #   end
    #   check_for_cql(item_ext, '', index, q_index, item_ext.url, link_id)
    # end

    # def check_nested_items(item, index, q_index, found_item_expressions, link_id)
    #   misformatted_nested_expressions = []
    #   item.item.each do |nested_item|
    #     check_nested_items(nested_item, index, q_index, found_item_expressions, nested_item.linkId)
    #     nested_item.extension.each do |item_ext|
    #       misformatted_nested_expressions << check_item_extension(item_ext, index, q_index, found_item_expressions,
    #                                                               link_id)
    #     end
    #   end
    #   misformatted_nested_expressions.compact
    # end

    # def check_expression_format(item_ext, index)
    #   return unless library_names.none?

    #   expression_passes = false
    #   library_names.each do |name|
    #     if item_ext.valueExpression.expression.start_with? "\"#{name}\""
    #       expression_passes = true
    #       break
    #     end
    #   end
    #   index unless expression_passes
    # end

    # def check_for_cql(extension, extension_name, index, q_index, url, link_id = '')
    #   return if extension.valueExpression.nil?
    #   return if extension.valueExpression.language == 'text/cql'

    #   cql_presence[extension_name] = false unless extension_name.blank?
    #   messages << if link_id.blank?
    #                 { type: 'info',
    #                   message: format_markdown("[extension #{index + 1}] in [questionnaire #{q_index + 1}]
    #                       contains expression that does not have content type of cql
    #                       (URL: #{url}).") }
    #               else
    #                 { type: 'info',
    #                   message: format_markdown("[item #{index + 1}] in [questionnaire #{q_index + 1}]
    #                       contains expression that does not have content type of cql
    #                       (linkId: #{link_id}, URL: #{url}).") }
    #               end
    # end

    # def extract_contained_questionnaires(questionnaire_responses)
    #   questionnaire_responses&.filter_map do |qr|
    #     qr.contained&.grep(FHIR::Questionnaire)
    #   end&.flatten&.compact
    # end

    def extract_questionnaires_from_bundles(questionnaire_bundles)
      questionnaire_bundles.filter_map do |qb|
        qb.entry.filter_map { |entry| entry.resource if entry.resource.is_a?(FHIR::Questionnaire) }
      end&.flatten&.compact
    end

    def perform_questionnaire_package_response_validation(resource, index)
      bundles = extract_questionnaire_bundles(resource)

      resource_is_valid?(
        resource:,
        profile_url: QUESTIONNAIRE_PACKAGE_PARAMETER_PROFILE,
        message_prefix: "Request #{index}: "
      )

      return if bundles.present?

      add_message(
        'error',
        "No Questionnaire Bundle found in response #{index}"
      )
    end

    def extract_questionnaire_bundles(resource)
      case resource&.resourceType
      when 'Bundle'
        [resource]
      when 'Parameters'
        extract_bundles_from_parameter(resource)
      else
        []
      end
    end

    def extract_bundles_from_parameter(parameter)
      return [] if parameter.blank?

      parameter.parameter&.filter_map do |param|
        param.resource if param.resource&.resourceType == 'Bundle'
      end
    end

    # def extract_questionnaire_from_questionnaire_package(questionnaire_pkg_json, questionnaire_url)
    #   resource = FHIR.from_contents(questionnaire_pkg_json)
    #   questionnaire_bundles = extract_questionnaire_bundles(resource)
    #   questionnaires = extract_questionnaires_from_bundles(questionnaire_bundles)

    #   questionnaires.find { |q| q.url == questionnaire_url }
    # end

    def extract_libraries_from_bundles(questionnaire_bundles)
      questionnaire_bundles.filter_map do |qb|
        qb.entry.filter_map { |entry| entry.resource if entry&.resource.is_a?(FHIR::Library) }
      end&.flatten&.compact
    end
  end
end
