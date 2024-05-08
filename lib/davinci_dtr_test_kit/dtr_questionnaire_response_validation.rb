require_relative 'fixtures'

module DaVinciDTRTestKit
  module DTRQuestionnaireResponseValidation
    include URLs
    include Fixtures

    CQL_EXPRESSION_EXTENSIONS = [
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
    ].freeze

    def validate_questionnaire_pre_population(request, test_id)
      assert request.url == questionnaire_response_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{questionnaire_response_url}"

      assert_valid_json(request.request_body)
      questionnaire_response = FHIR.from_contents(request.request_body)
      assert questionnaire_response.present?, 'Request does not contain a recognized FHIR object'
      assert_resource_type(:questionnaire_response, resource: questionnaire_response)

      assert_valid_resource(resource: questionnaire_response,
                            profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse')

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

      validation_errors = validate_cql_executed(template_questionnaire_response.item, questionnaire_response.item,
                                                questionnaire)

      # Requirement: The DTR client SHALL retrieve the FHIR resources specified in the dataRequirement section of a
      #              Library
      validation_errors.concat(validate_data_requirements_retrieved(template_questionnaire_response,
                                                                    questionnaire_response))

      validation_errors.each { |msg| messages << { type: 'error', message: msg } }
      assert validation_errors.blank?, 'QuestionnaireResponse is not conformant. Check messages for issues found.'
    end

    def validate_cql_executed(expected_items, actual_items, questionnaire, error_messages = [])
      questionnaire_cql_expression_link_ids = collect_questionnaire_cql_expression_link_ids(questionnaire.item)

      actual_items&.each do |item|
        link_id = item.linkId
        expected_item = find_item_by_link_id(expected_items, link_id)
        if questionnaire_cql_expression_link_ids.include?(link_id)
          answer = item.answer&.first
          expected_answer = expected_item.answer.first

          if answer.present?
            unless valid_pre_populated_item_source?(answer)
              error_messages << "Answer for question with linkId `#{link_id}` should be pre-populated. Expected " \
                                "origin.source to equal 'auto' or 'override'"
            end

            if AUTO_POPULATED_ANSWERS.values.include?(link_id) && !answer_value_equal?(expected_answer, answer)
              error_messages << "Unexpected pre-populated answer for question with linkId `#{link_id}`: " \
                                "expected `#{expected_answer.value.to_json}` and received `#{answer.value&.to_json}`"
            end
          else
            error_messages << "Expected a pre-populated answer for question with linkId #{link_id}, but found none"
          end
        end

        validate_cql_executed(expected_item.item, item.item, questionnaire, error_messages)
      end
      error_messages
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

    def valid_pre_populated_item_source?(answer)
      origin = find_extension(answer, 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin')
      source = find_extension(origin, 'source')

      source&.value == 'auto' || source&.value == 'override'
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
