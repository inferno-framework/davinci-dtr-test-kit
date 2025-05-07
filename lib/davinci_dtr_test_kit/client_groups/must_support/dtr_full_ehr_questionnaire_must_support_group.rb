require_relative '../../urls'
require_relative 'dtr_full_ehr_ms_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../shared/dtr_custom_questionnaire_package_validation_test'
require_relative 'dtr_must_support_attestation_test'
require_relative 'dtr_questionnaire_must_support_test'
require_relative 'questionnaire_must_support_elements'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireMustSupportGroup < Inferno::TestGroup
    include QuestionnaireMustSupportElements

    id :dtr_full_ehr_questionnaire_ms
    title 'Demonstrate Questionnaire Element Support'
    description %(
      ### Questionnaire Package Request and mustSupport Visual Inspection

      During this test, Inferno will wait for the client system to request the questionnaire(s) using the
      `$questionnaire-package` operation and will return the user-provided Questionnaire package for the
      tester to complete.

      The tester will then demonstrate that the client system supports the
      `mustSupport` elements defined in the [DTR Standard Questionnaire](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire)
      profile through visual inspection (e.g., rendering, UI behavior, or guidance).

      ### Profile Validation

        Inferno will validate that:
        - The $questionnaire-package request conforms to [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
        - The response to the `$questionnaire-package` operation conforms to the [Questionnaire Package
          operation definition](https://hl7.org/fhir/us/davinci-dtr/STU2/OperationDefinition-questionnaire-package.html).

      ### Must Support

      Each profile contains elements marked as "must support". Inferno expects to see each of
      these elements at least once. If at least one cannot be found, the test will skip.
      The test will look through the Questionnaire resources provided for these elements.
    )
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
    input_order :access_token

    # Test 1: wait for the $questionnaire-package request
    test from: :dtr_full_ehr_ms_qp_request
    # Test 2: validate the $questionnaire-package body
    test from: :dtr_qp_request_validation
    # Test 3: validate the user provided $questionnaire-package response
    test from: :dtr_custom_qp_validation
    # Test 4: must support test
    test from: :dtr_questionnaire_must_support,
         title: '[USER INPUT VALIDATION] All must support elements are provided in the static Questionnaire resources provided', # rubocop:disable Layout/LineLength
         verifies_requirements: ['hl7.fhir.us.davinci-dtr_2.0.1@65'],
         description: <<~DESCRIPTION
           The DTR client SHALL be able to handle all `mustSupport` elements defined in the
           [DTR Standard Questionnaire](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire)
           profile. This test will look through the provided Questionnaire resources for the following
           must support elements:

           #{STATIC_QUESTIONNAIRE.map { |el| "- #{el}" }.join("\n")}
         DESCRIPTION
    # Test 5: attest client system can handle `mustSupport` elements
    test from: :dtr_must_support_attest
  end
end
