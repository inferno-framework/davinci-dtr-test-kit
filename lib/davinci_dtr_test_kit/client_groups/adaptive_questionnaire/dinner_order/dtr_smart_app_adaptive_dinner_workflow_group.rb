require_relative '../../../tags'
require_relative 'dtr_smart_app_adaptive_initial_retrieval_group'
require_relative '../../smart_app/dtr_smart_app_prepopulation_attestation_test'
require_relative '../../smart_app/dtr_smart_app_prepopulation_override_attestation_test'
require_relative 'dtr_adaptive_followup_questions_group'
require_relative 'dtr_adaptive_completion_group'
require_relative '../../shared/dtr_questionnaire_response_prepopulation_test'

module DaVinciDTRTestKit
  class DTRSmartAppAdaptiveDinnerWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_adaptive_dinner_workflow
    title 'Dinner Order Adaptive Questionnaire Workflow'
    description %(
      This test validates that a DTR SMART App client can perform a full DTR Adaptive Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate their ability to:

      1. Fetch the adaptive questionnaire package
        ([DinnerOrderAdaptive](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_adaptive/questionnaire_dinner_order_adaptive.json))
      2. Fetch the first set of questions and render and pre-populate them appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled
      3. Answer the initial questions and request additional questions
      4. Complete the questionnaire and provide the completed QuestionnaireResponse
         with appropriate indicators for pre-populated and manually-entered data.
    )

    config(
      options: {
        smart_app: true
      }
    )

    group do
      id :dtr_smart_app_adaptive_retrieval
      title 'Retrieving the Adaptive Questionnaire'
      description %(
        Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and follow up with an initial $next-question request to retrieve
        the first set of questions.

        The initial set of questions will be returned for the tester to complete.

        Inferno will then validate the conformance of the requests.
      )
      run_as_group

      group from: :dtr_smart_app_adaptive_initial_retrieval
      group do
        id :dtr_smart_app_initial_questionnaire_rendering
        title 'Filling Out the Questionnaire'
        description %(
          The tester will interact with the questionnaire within their client system
          such that pre-population steps are taken, the questionnaire is rendered, and
          they are able to fill it out. The tester will attest that questionnaire pre-population
          and rendering directives were followed.
        )

        # Test 1: attest to the pre-population of the name fields
        test from: :dtr_smart_app_prepopulation_attest
        # Test 2: attest to the pre-population and edit of the location field
        test from: :dtr_smart_app_prepopulation_override_attest
      end
    end

    group from: :dtr_adaptive_followup_questions,
          config: {
            options: {
              accepts_multiple_requests: true,
              next_tag: "followup_#{CLIENT_NEXT_TAG}"
            },
            inputs: {
              access_token: { name: :client_id }
            }
          }

    group from: :dtr_adaptive_completion,
          config: {
            options: {
              accepts_multiple_requests: true,
              next_tag: "completion_#{CLIENT_NEXT_TAG}"
            },
            inputs: {
              access_token: { name: :client_id }
            }
          }
    group from: :dtr_smart_app_saving_qr do
      config(
        options: {
          adaptive: true,
          qr_profile_url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
        }
      )

      # Test 3: validate workflow-specific details such as pre-population and overrides
      test from: :dtr_qr_prepopulation,
           uses_request: :questionnaire_response_save
    end
  end
end
