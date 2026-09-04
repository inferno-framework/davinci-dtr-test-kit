require_relative '../../descriptions'
require_relative '../../../urls'
require_relative '../next_question_template_questionnaires'
require_relative '../../short_circuit_interaction_verification'

module DaVinciDTRTestKit
  class DTRFullEHRV220InteractionWaitTest < Inferno::Test
    include URLs
    include NextQuestionTemplateQuestionnaires
    include ShortCircuitInteractionVerification

    id :dtr_full_ehr_v220_interaction_wait
    title 'Retrieve and complete Questionnaire(s)'
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
      clear_short_circuit_flag
      unless run_tests?
        short_circuit_validation_tests(:pass)
        short_circuit_pass(message: config.options[:short_circuit_pass_message])
      end

      validate_response_template_inputs

      continuation_url = "#{resume_pass_url}?token=#{client_id}"
      output(continuation_url:)

      wait(
        identifier: client_id,
        timeout: 1200,
        message: %(
          Inferno will wait while the tester uses the system to complete
          one or more DTR Questionnaires retrieved from Inferno's simulated
          payer server.

          When all Questionnaire returned by Inferno during this period
          have been completed and saved to the EHR [Click here](#{continuation_url})
          to continue.

          ### Endpoints

          Available endpoints on Inferno's simulated payer server include

          - FHIR Base: `#{fhir_base_url}
          - Questionnaire Package Operation: `#{questionnaire_package_url}`
          - Next Question Operation: `#{next_url}`

          ### Authenticated and Identification

          Requests must be authenticated by first obtaining an access token
          for client `#{client_id}` from Inferno's token endpoint: `#{token_url}`.
          Only requests including an obtained access token as a bearer token
          in the `Authentication` header of the HTTP request will be recognized
          as associated with this session and return successful responses.
        )
      )
    end

    # other things that might go into the wait message
    # - Whether multiple successful $questionnaire-package requests are allowed (options)
    # - specific instructions for completion (TODO)
    # - whether the Questionnaires are provided by Inferno or the tester (options)

    private

    def run_tests?
      input_name = config.options[:short_circuit_pass_input]
      return true if input_name.blank?

      send(input_name) == 'true'
    end

    def validate_response_template_inputs
      validate_qp_response_template_input
      validate_nq_questionnaire_template_input
    rescue Inferno::Exceptions::AssertionException => e
      short_circuit_validation_tests(:skip)
      raise e
    end

    def validate_qp_response_template_input
      input_name = config.options[:qp_response_template_input]
      return if input_name.blank?

      title = input_title(input_name)
      value = send(input_name)
      assert value.present?, "No response template provided by the user in input '#{title}'."

      parsed = parse_qp_template_value(value, title)
      assert parsed.is_a?(FHIR::Parameters),
             "Input '#{title}' must contain a Parameters resource for the $questionnaire-package " \
             'response template.'
    end

    def parse_qp_template_value(value, title)
      FHIR.from_contents(value)
    rescue StandardError
      assert false, "Input '#{title}' does not contain valid JSON."
    end

    # Unlike the endpoint's own parsing (which silently discards array entries that aren't
    # Questionnaires, since the tester may legitimately be mid-workflow when a request comes in),
    # this pre-wait check fails on the first bad entry: there's no reason to let the tester start
    # the interaction with a template that's already known to be broken.
    def validate_nq_questionnaire_template_input
      input_name = config.options[:nq_questionnaire_template_input]
      return if input_name.blank?

      title = input_title(input_name)
      value = send(input_name)
      assert value.present?, "No response template provided by the user in input '#{title}'."

      parsed_json = JSON.parse(value)
      is_array = parsed_json.is_a?(Array)
      questionnaire_jsons = is_array ? parsed_json : [parsed_json]

      questionnaire_jsons.each_with_index do |questionnaire_json, index|
        next if parse_template_questionnaire(questionnaire_json).present?

        location = is_array ? "at index #{index} of input '#{title}'" : "in input '#{title}'"
        assert false, "Invalid $next-question response template: expected a Questionnaire #{location}."
      end
    rescue JSON::ParserError
      assert false, "Input '#{title}' does not contain valid JSON."
    end

    # config.options input references are stored as input names (e.g. 'additional_ms_qp_responses');
    # testers only ever see the input's title in the UI, so error messages should use that instead.
    def input_title(input_name)
      config.input(input_name.to_sym)&.title || input_name
    end
  end
end
