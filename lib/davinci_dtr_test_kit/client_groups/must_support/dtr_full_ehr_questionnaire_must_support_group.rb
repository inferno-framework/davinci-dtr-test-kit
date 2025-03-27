require_relative '../../urls'
require_relative '../custom_static/dtr_full_ehr_cutom_static_retrieval_group'
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
          questionnaire_package_tag: "must_support_#{QUESTIONNAIRE_PACKAGE_TAG}"
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

      group do
        title 'Retrieving the Adaptive Questionnaires for must support validation'
      end

      group do
        title '[USER INPUT VALIDATION] Adaptive Questionnaires Must Support'
        test 'All must support elements are provided in the adaptive Questionnaire resources provided' do
        end
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaire'
        test 'Attest rendering and filling of provided adaptive Questionnaire resources' do
        end
      end

      group do
        title 'Attestation: QuestionnaireResponse Completion and Storage'
      end
    end
  end
end
