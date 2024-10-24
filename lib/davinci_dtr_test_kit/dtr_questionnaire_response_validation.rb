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

    def verify_basic_conformance(questionnaire_response_json)
      check_is_questionnaire_response(questionnaire_response_json)
      assert_valid_resource(resource: FHIR.from_contents(questionnaire_response_json),
                            profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse|2.0.1')
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
        else
          check_origin_source(origin_source, link_id, is_cql_expression, override: expected_overrides.include?(link_id))
        end
      end
    end

    def check_origin_source(origin_source, link_id, is_cql_expression, override: false)
      if override
        origin_source_error(link_id, ['override'], origin_source) unless origin_source == 'override'
      elsif is_cql_expression && !['auto', 'override'].include?(origin_source)
        origin_source_error(link_id, 'auto or override', origin_source)
      elsif !is_cql_expression && origin_source != 'manual'
        origin_source_error(link_id, 'manual', origin_source)
      end
    end

    # This checks presence of all answers if link_ids is nil
    def check_answer_presence(items, link_ids: nil)
      items.each do |item|
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

      validate_cql_executed(questionnaire_response.item, questionnaire_cql_expression_link_ids,
                            template_prepopulation_expectations, template_override_expectations)

      if template_prepopulation_expectations.size.positive?
        add_message('error', %(Items expected to be pre-populated not found:
                               #{template_prepopulation_expectations.keys.join(', ')}))
      end

      if template_override_expectations.size.positive?
        add_message('error', %(Items expected to be pre-poplated and overridden not found:
                               #{template_override_expectations.keys.join(', ')}))
      end

      assert(messages.none? { |m| m[:type] == 'error' },
             'QuestionnaireResponse is not conformant. Check messages for issues found.')
    end

    def validate_cql_executed(actual_items, questionnaire_cql_expression_link_ids, template_prepopulation_expectations,
                              template_override_expectations)

      actual_items&.each do |item_to_validate|
        link_id = item_to_validate.linkId
        if questionnaire_cql_expression_link_ids.include?(link_id)
          if template_prepopulation_expectations.key?(link_id)
            check_item_prepopulation(item_to_validate, template_prepopulation_expectations.delete(link_id), false)
          elsif template_override_expectations.include?(link_id)
            check_item_prepopulation(item_to_validate, template_override_expectations.delete(link_id), true)
          else
            raise "template missing expectation for question `#{link_id}`"
          end
        end

        validate_cql_executed(item_to_validate.item, questionnaire_cql_expression_link_ids,
                              template_prepopulation_expectations, template_override_expectations)
      end
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

    def check_item_prepopulation(item, expected_answer, override)
      answer = item.answer.first
      link_id = item.linkId

      unless answer&.value&.present?
        add_message('error', "No answer for item `#{link_id}`")
        return
      end

      check_answer(link_id, override, expected_answer, answer)

      origin_source = find_origin_source(item)
      expected_origin_source = override ? 'override' : 'auto'

      if origin_source.present?
        unless origin_source == expected_origin_source
          origin_source_error(link_id, expected_origin_source, origin_source)
        end
      else
        add_message('error', "Required `origin.source` extension not present on answer to item `#{item.linkId}`")
      end
    end

    def check_answer(link_id, override, expected_answer, answer)
      if override && answer_value_equal?(expected_answer, answer)
        add_message('error', %(Answer to item `#{link_id}` was not overriden from the pre-populated value.
                               Found #{expected_answer}, but should be different))
      elsif !override && !answer_value_equal?(expected_answer, answer)
        add_message('error', %(Answer to item `#{link_id}` contains unexpected value. Expected:
                               #{value_for_display(expected_answer)}. Found #{value_for_display(answer)}))
      end
    end

    def origin_source_error(link_id, expected, actual)
      add_message('error', %(`origin.source` extension on item `#{link_id}` contains unexpected value.
                             Expected: #{expected}. Found: #{actual}))
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
