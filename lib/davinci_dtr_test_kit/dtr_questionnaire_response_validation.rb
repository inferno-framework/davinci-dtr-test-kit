# frozen_string_literal: true

module DaVinciDTRTestKit
  module DTRQuestionnaireResponseValidation
    CQL_EXPRESSION_EXTENSIONS = [
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
    ].freeze

    def check_is_questionnaire_response(questionnaire_response_json)
      assert_valid_json(questionnaire_response_json)
      questionnaire_response = begin
        FHIR.from_contents(questionnaire_response_json)
      rescue StandardError
        nil
      end

      assert questionnaire_response.present?, 'The QuestionnaireResponse is not a recognized FHIR object'
      assert_resource_type(:questionnaire_response, resource: questionnaire_response)
    end

    def verify_basic_conformance(questionnaire_response_json, profile_url = nil)
      profile_url ||= 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse|2.0.1'
      check_is_questionnaire_response(questionnaire_response_json)
      assert_valid_resource(resource: FHIR.from_contents(questionnaire_response_json), profile_url:)
    end

    # This only checks answers in the questionnaire response, meaning it does not catch missing answers
    def check_origin_sources(questionnaire_items, response_items, expected_overrides: [])
      response_items&.each do |response_item|
        check_origin_sources(questionnaire_items, response_item.item, expected_overrides:)
        next unless response_item.answer&.any?

        link_id = response_item.linkId
        origin_source = find_origin_source(response_item)
        questionnaire_item = find_item_by_link_id(questionnaire_items, link_id)
        is_cql_expression = item_is_cql_expression?(questionnaire_item)

        if origin_source.nil?
          add_message('error', "Required `origin.source` extension not present on answer to item `#{link_id}`")
        elsif expected_overrides.include?(link_id)
          if origin_source != 'override'
            add_message('error', %(`origin.source` extension on item `#{link_id}` contains unexpected value. Expected:
                                   override. Found: #{origin_source}))
          end
        elsif is_cql_expression && !['auto', 'override'].include?(origin_source)
          add_message('error', %(`origin.source` extension on item `#{link_id}` contains unexpected value. Expected:
                                 auto or override. Found: #{origin_source}))
        elsif !is_cql_expression && origin_source != 'manual'
          add_message('error', %(`origin.source` extension on item `#{link_id}` contains unexpected value. Expected:
                                 manual. Found: #{origin_source}))
        end
      end
    end

    # This checks presence of all answers if link_ids is nil
    def check_answer_presence(items, link_ids: nil)
      items&.each do |item|
        check_answer_presence(item.item, link_ids:)

        if !item.answer&.first&.value.present? && (link_ids.nil? || link_ids.include?(item.linkId))
          add_message('error', "No answer for item #{item.linkId}")
        end
      end
    end

    # Requirements:
    #  - Prior to exposing the draft QuestionnaireResponse to the user for completion and/or review, the DTR client
    #    SHALL execute all CQL necessary to resolve the initialExpression, candidateExpression and
    #    calculatedExpression extensions found in the Questionnaire for any enabled elements.
    #  - All items that are pre-populated (whether by the payer in the initial QuestionnaireResponse provided in the
    #    questionnaire package, or from data retrieved from the EHR) SHALL have their origin.source set to ‘auto’.
    def validate_questionnaire_pre_population(questionnaire, template_questionnaire_response, questionnaire_response)
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

      if template_prepopulation_expectations.size.positive?
        validation_errors << 'Items expected to be pre-populated not found: ' \
                             "#{template_prepopulation_expectations.keys.join(', ')}"
      end

      if template_override_expectations.size.positive?
        validation_errors << 'Items expected to be pre-poplated and overridden not found: ' \
                             "#{template_override_expectations.keys.join(', ')}"
      end

      validation_errors.each { |msg| messages << { type: 'error', message: msg } }
      assert validation_errors.blank?, 'QuestionnaireResponse is not conformant. Check messages for issues found.'
    end

    def validate_cql_executed(actual_items, questionnaire_cql_expression_link_ids, template_prepopulation_expectations,
                              template_override_expectations, error_messages)

      actual_items&.each do |item_to_validate|
        link_id = item_to_validate.linkId
        if questionnaire_cql_expression_link_ids.include?(link_id)
          if template_prepopulation_expectations.key?(link_id)
            check_item_prepopulation(item_to_validate, template_prepopulation_expectations.delete(link_id),
                                     error_messages, false)
          elsif template_override_expectations.include?(link_id)
            check_item_prepopulation(item_to_validate, template_override_expectations.delete(link_id), error_messages,
                                     true)
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

        origin_source = find_origin_source(target_item)

        unless origin_source.present?
          raise "Template QuestionnaireResponse item `#{target_link_id}` missing the `origin.source` extension"
        end

        if origin_source == 'auto'
          expected_prepopulated[target_link_id] = target_item_answer
        elsif origin_source == 'override'
          expected_overrides[target_link_id] = target_item_answer
        else
          raise "`origin.source` extension for item `#{target_link_id}` has unexpected value: #{origin_source}"
        end
      end
    end

    def check_item_prepopulation(item, expected_answer, error_list, override)
      answer = item.answer.first
      if answer&.value&.present?
        # check answer
        if override && answer_value_equal?(expected_answer, answer)
          error_list << "Answer to item `#{item.linkId}` was not overriden from the pre-populated value. " \
                        "Found #{expected_answer}, but should be different"
        elsif !override && !answer_value_equal?(expected_answer, answer)
          error_list << "answer to item `#{item.linkId}` contains unexpected value. Expected: \
          #{value_for_display(expected_answer)}. Found #{value_for_display(answer)}"
        end

        # check origin.source extension
        origin_source = find_origin_source(item)

        if origin_source.present?
          expected_source_value = override ? 'override' : 'auto'
          if origin_source != expected_source_value
            error_list << "`origin.source` extension on item `#{item.linkId}` contains unexpected value. Expected: " \
                          "#{expected_source_value}. Found #{origin_source}"
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

    def find_origin_source(item)
      origin_extension = find_extension(
        item&.answer&.first,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin'
      )
      find_extension(origin_extension, 'source')&.value
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

    def value_for_display(answer)
      return "#{answer.value&.system}|#{answer.value&.code}" if answer.valueCoding.present?

      answer.value
    end
  end
end
