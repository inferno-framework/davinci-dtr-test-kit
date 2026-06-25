require_relative '../../descriptions'
require_relative '../../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRV220InteractionWaitTest < Inferno::Test
    include URLs

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
  end
end
