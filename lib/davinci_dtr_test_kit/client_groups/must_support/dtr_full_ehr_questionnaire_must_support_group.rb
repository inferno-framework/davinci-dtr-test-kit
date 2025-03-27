require_relative '../../urls'
require_relative '../custom_static/dtr_full_ehr_cutom_static_retrieval_group'
require_relative '../adaptive_questionnaire/custom/dtr_full_ehr_custom_adaptive_retrieval_group'
require_relative 'dtr_must_support_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_store_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireMustSupportGroup < Inferno::TestGroup
    id :dtr_full_ehr_questionnaire_ms
    title 'Demonstrate Element Support'
    description %()
    input_order :access_token

    group do
      run_as_group
      title 'Static Questionnaires Element Support'
      description %()
      config(
        options: {
          questionnaire_package_tag: "ms_static_#{QUESTIONNAIRE_PACKAGE_TAG}"
        },
        inputs: {
          custom_questionnaire_package_response: {
            name: 'ms_custom_questionnaire_package_response',
            title: 'Custom Questionnaire Package Response JSON for Must Support tests',
            description: %(
                Provide a JSON `$questionnaire-package` response (a FHIR Parameters resource)
                containing one or more `PackageBundle` entries. Inferno will return this as
                the response to the `$questionnaire-package` request.
                The Questionnaire in each `PackageBundle` **must include all `mustSupport` elements**
                as defined in the DTR Standard Questionnaire profile.
              )

          }
        }
      )

      group from: :dtr_full_ehr_custom_static_retrieval do
        title 'Retrieving the Static Questionnaires for must support validation'
        description %(
          During this test, DTR will be launch in the Full EHR to start the demonstration of
          static Questionnaire capabilities.
          After DTR launch, Inferno will wait for the client system to request the questionnaire(s) using the
          $questionnaire-package operation and will return the user-provided questionnaire package for the
          tester to complete. Inferno will then validate the the conformance of the request
          and of the provided Questionnaire Package that Inferno responded with.
        )
      end

      group do
        title '[USER INPUT VALIDATION] Static Questionnaires Must Support'
        test 'All must support elements are provided in the static Questionnaire resources provided' do
          run { omit 'Not yet implemented' }
        end
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaires'

        test from: :dtr_must_support_attest
      end

      group do
        title 'Attestation: QuestionnaireResponse Completion and Storage'

        test from: :dtr_full_ehr_store_attest,
             description: %(
                Attest that all provided questionnaires have been completed and their responses have been
                persisted and can be exported as FHIR QuestionnaireResponse instances.
              )
      end
    end

    group do
      run_as_group
      title 'Adaptive Questionnaires Element Support'
      description %()
      config(
        options: {
          form_type: 'adaptive',
          questionnaire_package_tag: "ms_adaptive_#{QUESTIONNAIRE_PACKAGE_TAG}",
          next_tag: "custom_ms_adaptive_#{CLIENT_NEXT_TAG}"
        },
        inputs: {
          custom_questionnaire_package_response: {
            name: 'ms_adaptive_custom_questionnaire_package_response',
            title: 'Custom Adaptive Questionnaire Package Response JSON for Must Support tests',
            description: %(
                Provide a JSON `$questionnaire-package` response (a FHIR Parameters resource).
                Inferno will return this as the response to the `$questionnaire-package` request.
                The Questionnaire in the `PackageBundle` **must include all `mustSupport` elements**
                as defined in the DTR Adaptive Questionnaire profile.
                Note: Ensure that the questionnaire package has an empty Adaptive Questionnaire.
              )

          },
          custom_next_question_questionnaires: {
            name: 'ms_custom_next_question_questionnaires',
            title: 'Custom Questionnaire resources to include in each $next-question Response for Must Support tests',
            description: %(
              Provide a JSON list of Questionnaire resources for Inferno to use when updating
              the contained Questionnaire in the `QuestionnaireResponse` received in each
              `$next-question` request.

              Each `$next-question` request will correspond to the next item in the provided list,
              and Inferno will replace the contained Questionnaire with the corresponding resource
              before returning the updated `QuestionnaireResponse`.

              The provided Questionnaires must contain the next question or set of questions in
              sequence, ensuring a proper progression of the adaptive questionnaire workflow.
              Each Questionnaire **must include all `mustSupport` elements** as defined in the
              DTR Adaptive Questionnaire profile.
            ),
            type: 'textarea'
          }
        }
      )

      group from: :dtr_full_ehr_custom_adaptive_retrieval do
        title 'Retrieving the Adaptive Questionnaires for must support validation'
        description %(
          During this test, DTR will be launched within the Full EHR to begin the demonstration of
          Adaptive Questionnaire capabilities.

          Once DTR is launched, Inferno will wait for client requests to retrieve and progress through
          the adaptive questionnaire workflow:

          - **Questionnaire Package Request**: The client should invoke the `$questionnaire-package`
            operation to retrieve the adaptive questionnaire package. Inferno will respond with the
            user-provided empty adaptive questionnaire.

          - **Next Question Requests**: The client should invoke the `$next-question` operation to
            request the next set of questions. Inferno will respond sequentially with the next
            Questionnaire from the user-provided list. If a `$next-question` request is received
            when the list is empty, Inferno will mark the QuestionnaireResponse as completed.

          Inferno will validate that:
          - The response to the `$questionnaire-package` operation conforms to the [Questionnaire Package
            operation definition](https://hl7.org/fhir/us/davinci-dtr/STU2/OperationDefinition-questionnaire-package.html).
          - Each user-provided Questionnaire resource included in a `$next-question` response is valid
            and appropriate for the workflow.
        )
      end

      group do
        title '[USER INPUT VALIDATION] Adaptive Questionnaires Must Support'
        test 'All must support elements are provided in the adaptive Questionnaire resources provided' do
          run { omit 'Not yet implemented' }
        end
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaire'

        test from: :dtr_must_support_attest
      end

      group do
        title 'Attestation: QuestionnaireResponse Completion and Storage'

        test from: :dtr_full_ehr_store_attest
      end
    end
  end
end
