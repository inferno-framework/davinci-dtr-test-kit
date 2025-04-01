require_relative '../../urls'
require_relative '../custom_static/dtr_smart_app_custom_static_retrieval_group'
require_relative 'dtr_questionnaire_must_support_test'
require_relative 'dtr_must_support_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_store_attestation_test'
require_relative '../shared/dtr_prepopulation_attestation_test'
require_relative '../smart_app/dtr_smart_app_saving_questionnaire_response_group'
require_relative '../smart_app/dtr_smart_app_questionnaire_response_correctness_test'

module DaVinciDTRTestKit
  class DTRSmartAppQuestionnaireMustSupportGroup < Inferno::TestGroup
    id :dtr_smart_app_questionnaire_ms
    title 'Demonstrate Element Support'
    description %()

    group do
      title 'Static Questionnaires Element Support'
      description %()
      run_as_group
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

      group from: :dtr_smart_app_custom_static_retrieval,
            title: 'Retrieving the Static Questionnaires for must support validation'

      group do
        title '[USER INPUT VALIDATION] Static Questionnaires Must Support'

        test from: :dtr_questionnaire_must_support,
             title: 'All must support elements are provided in the static Questionnaire resources provided',
             description: %()
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaires'
        description %(
          This group verifies that the tester has properly followed pre-population and rendering
          directives while interacting with and filling out the questionnaire(s).

          After retrieving and completing each questionnaire in their client system, the tester will
          attest that:
          1. The client system can handle `mustSupport` elements by displaying appropriate visual cues or
            guidance where those elements impact expected user actions.
          2. Each questionnaire was pre-populated as expected, with at least two answers pre-populated.
          3. Each questionnaire was rendered correctly according to its defined structure.
          4. They were able to manually enter responses, including overriding pre-populated answers.
        )

        test from: :dtr_must_support_attest
        test from: :dtr_prepopulation_attest
        test from: :dtr_prepopulation_override_attest
      end

      group from: :dtr_smart_app_saving_qr do
        config(options: { custom: true })
        test from: :dtr_smart_app_qr_correctness,
             uses_request: :questionnaire_response_save
      end
    end
  end
end
