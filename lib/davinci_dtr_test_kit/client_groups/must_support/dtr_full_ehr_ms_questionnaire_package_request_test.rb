require_relative '../../descriptions'
require_relative '../../urls'
require_relative 'questionnaire_must_support_elements'

module DaVinciDTRTestKit
  class DTRFullEHRMSQuestionnairePackageRequestTest < Inferno::Test
    include URLs
    include QuestionnaireMustSupportElements

    id :dtr_full_ehr_ms_qp_request
    title 'Invoke the Questionnaire Package Operation and Demonstrate mustSupport Handling'
    description <<~DESCRIPTION
      Inferno will wait for a DTR Questionnaire package request from the client. Upon receipt,
      Inferno will return the user-provided Questionnaire package as the response to the $questionnaire-package request.

      Afterward, Inferno will wait for the user to visually demonstrate support (via UI cues or guidance)
      for the following mustSupport elements, as defined in the [DTR Standard Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire):

        #{STATIC_QUESTIONNAIRE.map { |el| "- #{el}" }.join("\n")}
    DESCRIPTION
    config options: { accepts_multiple_requests: true }
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@165', 'hl7.fhir.us.davinci-dtr_2.0.1@242'
    input :custom_questionnaire_package_response
    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED

    run do
      assert_valid_json(
        custom_questionnaire_package_response,
        'Custom questionnaire package response is not a valid json'
      )

      custom_qp = JSON.parse(custom_questionnaire_package_response)
      assert custom_qp.present?, %(
        Custom questionnaire package response is empty, please provide a custom questionnaire package response
        for the $questionnaire-package request
      )

      wait(
        identifier: client_id,
        timeout: 1800,
        message: <<~MESSAGE
          ### Questionnaire Package

          Inferno will wait for the Full EHR to invoke the DTR Questionnaire Package operation by sending a POST
          request to

          `#{questionnaire_package_url}`

          Inferno will return the **user-provided Questionnaire package** in the response.

          ### MustSupport Elements Visual Inspection

          After the Questionnaire package is loaded, complete the form(s) within the client system and
          **visually inspect** that the application correctly supports all mustSupport elements as defined in the
          [DTR Standard Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire).
          Support should be demonstrated via visual cues, UI behavior, or other relevant indicators.

          The mustSupport elements include:

          #{STATIC_QUESTIONNAIRE.map { |el| "- #{el}" }.join("\n")}

          ### Continuing the Tests

          Once the Questionnaire has been loaded and the visual inspection is complete,
          [Click here](#{resume_pass_url}?token=#{client_id}) to continue.
        MESSAGE
      )
    end
  end
end
