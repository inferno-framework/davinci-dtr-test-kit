require_relative '../../descriptions'
require_relative '../../../urls'
require_relative '../next_question_template_questionnaires'

module DaVinciDTRTestKit
  class DTRFullEHRV220InteractionWaitTest < Inferno::Test
    include URLs
    include NextQuestionTemplateQuestionnaires

    id :dtr_full_ehr_v220_interaction_wait
    title 'Retrieve and complete the Questionnaire'
    description %(
      Inferno will act as a Payer DTR Server while the tester launches DTR and completes the questionnaire.
    )

    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: false,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED
    # input :questionaire_package_response_template,
    #       title: '$questionnaire-package Response Template',
    #       type: 'textarea',
    #       optional: true,
    #       description: %(
    #         Template used to generate responses to invocations of the $questionnaire-package
    #         operation. This will be a single Parameters resource in json form. Inferno will
    #         select the `parameter` entries within it to return based on selection criteria
    #         within the template evaluated against the request details.
    #       ),
    #       default: '{ "ResourceType": "Parameters" }'
    # input :next_question_response_template,
    #       title: '$next-question Response Template',
    #       type: 'textarea',
    #       optional: true,
    #       description: %(
    #         Template used to generate responses to invocations of the $questionnaire-package
    #         operation. This will be a list of Questionnaire resources in json form. Inferno
    #         will select which Questionnaire to use based on the Questionnaire url indicated
    #         in the request and will select the `item` entries to add based on selection criteria
    #         within the template evaluated against the request details.
    #       ),
    #       default: '[]'
    # input :value_set_expansions,
    #       title: 'ValueSet $expand Data',
    #       type: 'textarea',
    #       optional: true,
    #       description: %(
    #         Template used to generate responses to invocations of the ValueSet/$expand
    #         operation. This will be a list of ValueSet resources in json form. Inferno
    #         will select the entry to use by matching the `url` parameter against the
    #         ValueSet `url` element.
    #       ),
    #       default: '[]'
    output :continuation_url

    run do
      validate_response_template_inputs

      continuation_url = "#{resume_pass_url}?token=#{client_id}"
      output(continuation_url:)

      wait(
        identifier: client_id,
        timeout: 600,
        message: %(
          ### Questionnaires

          Inferno will wait while the tester launches DTR within the client system and uses it
          to complete a questionnaire.

          Available endpoints on Inferno's simulated payer server include

          - FHIR Base: `#{fhir_base_url}
          - Questionnaire Package Operation: `#{questionnaire_package_url}`
          - Next Question Operation: `#{next_url}`

          ### Authenticated and Identification

          Requests must be authenticated by first obtaining an access token
          for client `#{client_id}` from Inferno's token endpoint: `#{token_url}`.

          ### Continuing the Tests

          When the questionnaire has been completed and saved to the EHR
          [Click here](#{continuation_url}) to continue.
        )
      )
    end

    private

    def validate_response_template_inputs
      validate_qp_response_template_input
      validate_nq_questionnaire_template_input
    end

    def validate_qp_response_template_input
      input_name = config.options[:qp_response_template_input]
      return if input_name.blank?

      value = send(input_name)
      assert value.present?, "No response template provided by the user in input '#{input_name}'."

      parsed = parse_qp_template_value(value, input_name)
      assert parsed.is_a?(FHIR::Parameters),
             "Input '#{input_name}' must contain a Parameters resource for the $questionnaire-package " \
             'response template.'
    end

    def parse_qp_template_value(value, input_name)
      FHIR.from_contents(value)
    rescue StandardError
      assert false, "Input '#{input_name}' does not contain valid JSON."
    end

    # Unlike the endpoint's own parsing (which silently discards array entries that aren't
    # Questionnaires, since the tester may legitimately be mid-workflow when a request comes in),
    # this pre-wait check fails on the first bad entry: there's no reason to let the tester start
    # the interaction with a template that's already known to be broken.
    def validate_nq_questionnaire_template_input
      input_name = config.options[:nq_questionnaire_template_input]
      return if input_name.blank?

      value = send(input_name)
      assert value.present?, "No response template provided by the user in input '#{input_name}'."

      parsed_json = JSON.parse(value)
      is_array = parsed_json.is_a?(Array)
      questionnaire_jsons = is_array ? parsed_json : [parsed_json]

      questionnaire_jsons.each_with_index do |questionnaire_json, index|
        next if parse_template_questionnaire(questionnaire_json).present?

        location = is_array ? "at index #{index} of input '#{input_name}'" : "in input '#{input_name}'"
        assert false, "Invalid $next-question response template: expected a Questionnaire #{location}."
      end
    rescue JSON::ParserError
      assert false, "Input '#{input_name}' does not contain valid JSON."
    end
  end
end
