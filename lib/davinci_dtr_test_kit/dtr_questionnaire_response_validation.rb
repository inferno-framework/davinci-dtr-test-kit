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

    def validate_questionnaire_pre_population(request)
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
      validation_errors = validate_cql_executed(standard_questionnaire, questionnaire_response)

      # Requirement: The DTR client SHALL retrieve the FHIR resources specified in the dataRequirement section of a
      #              Library
      validation_errors.concat(validate_data_requirements_retrieved(questionnaire_response))

      validation_errors.each { |msg| messages << { type: 'error', message: msg } }
      assert validation_errors.blank?, 'QuestionnaireResponse is not conformant. Check messages for issues found.'
    end

    def validate_cql_executed(questionnaire, questionnaire_response)
      link_ids = collect_questionnaire_cql_expression_link_ids(questionnaire.item)
      validate_questionnaire_response_item_source(questionnaire_response.item, link_ids)
    end

    def validate_data_requirements_retrieved(questionnaire_response)
      error_messages = []
      data_req_condition_system = 'http://hl7.org/fhir/sid/icd-10-cm'
      data_req_condition_code = 'J44.9'

      answer = find_answer_by_link_id(questionnaire_response.item, '3.1')
      data_req_answer = answer&.find do |a|
        a.valueCoding&.present? &&
          a.valueCoding&.system == data_req_condition_system &&
          a.valueCoding&.code == data_req_condition_code
      end
      unless data_req_answer.present?
        error_messages << "dataRequirement not satisfied for Library 'RAD Prepopulation'. Expected answer to " \
                          "question with linkId `3.1` to have coding with system: '`#{data_req_condition_system}`' " \
                          "and value: '`#{data_req_condition_code}`'"
      end
      error_messages
    end

    def collect_questionnaire_cql_expression_link_ids(items, link_ids = [])
      items.each do |item|
        link_ids << item.linkId if item_is_cql_expression?(item)
        collect_questionnaire_cql_expression_link_ids(item.item, link_ids) if item&.item&.any?
      end
      link_ids
    end

    def validate_questionnaire_response_item_source(items, link_ids, error_messages = [])
      items&.each do |item|
        if link_ids.include?(item.linkId)
          # We assume there is only one answer value. The IG does not specify expectations when there are multiple.
          answer = item.answer&.find { |a| a.value.present? }
          unless answer.present?
            error_messages << "CQL has not been executed for question with linkId #{item.linkId}"
            next
          end

          origin = find_extension(answer, 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin')
          source = find_extension(origin, 'source')
          unless source&.value == 'auto'
            error_messages << "Pre-populated answer for question with linkId `#{item.linkId}` does not have " \
                              "origin.source of 'auto'"
          end
        end

        validate_questionnaire_response_item_source(item.item, link_ids, error_messages)
      end
      error_messages
    end

    def item_is_cql_expression?(item)
      item.extension&.any? { |ext| CQL_EXPRESSION_EXTENSIONS.include?(ext.url) }
    end

    def find_extension(element, url)
      element&.extension&.find { |e| e.url == url }
    end

    def find_answer_by_link_id(items, link_id)
      items.each do |item|
        return item.answer if item.linkId == link_id

        match = find_answer_by_link_id(item.item, link_id)
        return match if match
      end
      nil
    end
  end
end
