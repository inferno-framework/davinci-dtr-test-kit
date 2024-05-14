require_relative 'fixtures'

module DaVinciDTRTestKit
  module DTRQuestionnaireResponseValidation
    include Fixtures

    CQL_EXPRESSION_EXTENSIONS = [
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
    ].freeze

    def validate_questionnaire_pre_population(questionnaire_response, test_id)
      # Requirements:
      #  - Prior to exposing the draft QuestionnaireResponse to the user for completion and/or review, the DTR client
      #    SHALL execute all CQL necessary to resolve the initialExpression, candidateExpression and
      #    calculatedExpression extensions found in the Questionnaire for any enabled elements.
      #  - All items that are pre-populated (whether by the payer in the initial QuestionnaireResponse provided in the
      #    questionnaire package, or from data retrieved from the EHR) SHALL have their origin.source set to ‘auto’.
      #
      # Note that in the questionnaire fixture, all cql expression elements are enabled, so we don't filter
      template_questionnaire_response = find_questionnaire_response_for_test_id(test_id)
      raise "missing QuestionnaireResponse template for test #{test_id}" unless template_questionnaire_response.present?

      questionnaire = find_questionnaire_instance_for_test_id(test_id)
      raise "missing Questionnaire for test #{test_id}" unless questionnaire.present?

      questionnaire_cql_expression_link_ids = collect_questionnaire_cql_expression_link_ids(questionnaire.item)
      template_prepopulation_expectations = {}
      template_override_expectations = {}
      extract_expected_answers_from_template(template_questionnaire_response,
                                             questionnaire_cql_expression_link_ids,
                                             template_prepopulation_expectations,
                                             template_override_expectations)
      validation_errors = []
      validate_cql_executed(questionnaire_response.item, questionnaire_cql_expression_link_ids,
                            template_prepopulation_expectations, template_override_expectations, validation_errors)

      validation_errors.each { |msg| messages << { type: 'error', message: msg } }
      assert validation_errors.blank?, 'QuestionnaireResponse is not conformant. Check messages for issues found.'
    end

    def validate_cql_executed(actual_items, questionnaire_cql_expression_link_ids, template_prepopulation_expectations,
                              template_override_expectations, error_messages)

      actual_items&.each do |item_to_validate|
        link_id = item_to_validate.linkId
        if questionnaire_cql_expression_link_ids.include?(link_id)
          if template_prepopulation_expectations.key?(link_id)
            check_item_prepopulation(item_to_validate, template_prepopulation_expectations[link_id], error_messages,
                                     false)
          elsif template_override_expectations.include?(link_id)
            check_item_prepopulation(item_to_validate, template_override_expectations[link_id], error_messages, true)
          else
            raise "template missing expectation for question `#{link_id}`"
          end
        end

        validate_cql_executed(item_to_validate.item, questionnaire_cql_expression_link_ids,
                              template_prepopulation_expectations, template_override_expectations, error_messages)
      end
      error_messages
    end

    def extract_expected_answers_from_template(template_questionnaire_response,
                                               questionnaire_cql_expression_link_ids,
                                               expected_prepopulated = {},
                                               expected_overrides = {})

      questionnaire_cql_expression_link_ids.each do |target_link_id|
        target_item = find_item_by_link_id(template_questionnaire_response.item, target_link_id)
        raise "Template QuestionnaireResponse missing item with link id `#{target_link_id}`" unless target_item.present?

        target_item_answer = target_item.answer.first
        unless target_item_answer.present?
          raise "Template QuestionnaireResponse missing an answer for item with link id `#{target_link_id}`"
        end

        origin_extension = find_extension(target_item_answer,
                                          'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin')
        source_extension = find_extension(origin_extension, 'source')

        unless source_extension.present?
          raise "Template QuestionnaireResponse item `#{target_link_id}` missing the `origin.source` extension"
        end

        # TODO: handle other data types
        if source_extension.value == 'auto'
          expected_prepopulated[target_link_id] = target_item_answer.value
        elsif source_extension.value == 'override'
          expected_overrides[target_link_id] = target_item_answer.value
        else
          raise "`origin.source` extension for item `#{target_link_id}` has unexpected value: #{source_extension.value}"
        end
      end
    end

    def validate_data_requirements_retrieved(expected_questionnaire_response, questionnaire_response)
      error_messages = []

      DATA_REQUIREMENT_ANSWERS.each do |library_name, link_id|
        expected = find_item_by_link_id(expected_questionnaire_response.item, link_id).answer.first.value
        actual = find_item_by_link_id(questionnaire_response.item, link_id)&.answer&.first&.value
        next if coding_equal?(expected, actual)

        error_messages << "dataRequirement not satisfied for Library '#{library_name}'. Expected answer to " \
                          "question with linkId `#{link_id}` to have coding with system: '`#{expected.system}`' " \
                          "and value: '`#{expected.code}`'"
      end
      error_messages
    end

    def check_item_prepopulation(item, expected_answer, error_list, override)
      answer = item.answer.first
      if answer.present?
        # check answer
        if answer.value.present?
          if override && answer.value == expected_answer
            error_list << "Answer to item `#{item.linkId}` was not overriden from the pre-populated value. " \
                          "Found #{expected_answer}, but should be different"
          elsif answer.value != expected_answer
            error_list << "answer to item `#{item.linkId}` contains unexpected value. Expected: #{expected_answer}. " \
                          "Found #{answer.value}"
          end
        else
          error_list << "No answer for item `#{item.linkId}`"
        end

        # check origin.source extension
        origin_extension = find_extension(answer,
                                          'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin')
        source_extension = find_extension(origin_extension, 'source')

        if source_extension.present?
          expected_source_value = override ? 'override' : 'auto'
          if source_extension.value != expected_source_value
            error_list << "`origin.source` extension on item `#{item.linkId}` contains unexpected value. Expected: " \
                          "#{expected_source_value}. Found #{source_extension.value}"
          end
        else
          error_list << "Required `origin.source` extension not present on answer to item `#{item.linkId}`"
        end
      else
        error_list << "No answer for item `#{item.linkId}`"
      end
    end

    def find_item_by_link_id(items, link_id)
      items.each do |item|
        return item if item.linkId == link_id

        match = find_item_by_link_id(item.item, link_id)
        return match if match
      end
      nil
    end

    def find_extension(element, url)
      element&.extension&.find { |e| e.url == url }
    end

    def collect_questionnaire_cql_expression_link_ids(items, link_ids = [])
      items.each do |item|
        link_ids << item.linkId if item_is_cql_expression?(item)
        collect_questionnaire_cql_expression_link_ids(item.item, link_ids) if item&.item&.any?
      end
      link_ids
    end

    def item_is_cql_expression?(item)
      item.extension&.any? { |ext| CQL_EXPRESSION_EXTENSIONS.include?(ext.url) }
    end

    def answer_value_equal?(expected, actual)
      return coding_equal?(expected.value, actual.value) if expected.valueCoding.present?

      expected.value == actual.value
    end

    def coding_equal?(expected, actual)
      expected.system == actual&.system && expected.code == actual&.code
    end
  end
end
