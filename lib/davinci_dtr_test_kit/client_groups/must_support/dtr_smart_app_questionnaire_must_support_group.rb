require_relative '../../urls'
require_relative 'dtr_smart_app_ms_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../shared/dtr_custom_questionnaire_package_validation_test'
require_relative 'dtr_questionnaire_must_support_test'
require_relative 'dtr_must_support_attestation_test'
require_relative 'dtr_smart_app_ms_adaptive_request_test'
require_relative '../adaptive_questionnaire/dtr_adaptive_next_question_request_validation_test'
require_relative '../adaptive_questionnaire/dtr_adaptive_response_validation_test'
require_relative '../adaptive_questionnaire/custom/dtr_custom_next_question_response_validation_test'
require_relative 'questionnaire_must_support_elements'

module DaVinciDTRTestKit
  class DTRSmartAppQuestionnaireMustSupportGroup < Inferno::TestGroup
    include QuestionnaireMustSupportElements

    id :dtr_smart_app_questionnaire_ms
    title 'Demonstrate Element Support'
    description %()

    group do
      title 'Static Questionnaires Element Support'
      description %(
        ### Questionnaire Package Request and mustSupport Visual Inspeection

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

      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_smart_app_ms_qp_request
      # Test 2: validate the $questionnaire-package body
      test from: :dtr_qp_request_validation
      # Test 3: validate the user provided $questionnaire-package response
      test from: :dtr_custom_qp_validation
      # Test 4: must support test
      test from: :dtr_questionnaire_must_support,
           title: '[USER INPUT VALIDATION] All must support elements are provided in the static Questionnaire resources provided', # rubocop:disable Layout/LineLength
           description: <<~DESCRIPTION
             The DTR client SHALL be able to handle all `mustSupport` elements defined in the
             [DTR Standard Questionnaire ](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire)
             profile. This test will look through the provided Questionnaire resources for the following
             must support elements:

             #{STATIC_QUESTIONNAIRE.map { |el| "- #{el}" }.join("\n")}
           DESCRIPTION
      # Test 5: attest client system can handle `mustSupport` elements
      test from: :dtr_must_support_attest
    end

    group do
      run_as_group
      title 'Adaptive Questionnaires Element Support'
      description %(
        ### Adaptive Questionnaire requests

        During this test, Inferno will wait for client requests to retrieve and progress through
        the adaptive questionnaire workflow:

          - **Questionnaire Package Request**: The client should invoke the `$questionnaire-package`
            operation to retrieve the adaptive questionnaire package. Inferno will respond with the
            user-provided empty adaptive questionnaire.

          - **Next Question Requests**: The client should invoke the `$next-question` operation to
            request the next set of questions. Inferno will respond sequentially with the next
            Questionnaire from the user-provided list. If a `$next-question` request is received
            when the list is empty, Inferno will mark the QuestionnaireResponse as completed.

          - **mustSupport Visual Inspection**: The tester will demonstrate that the client system supports the
            `mustSupport` elements defined in the [DTR Questionnaire for adaptive form](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt)
            profile through visual inspection (e.g., rendering, UI behavior, or guidance).

        ### Profile Validation

        Inferno will validate that:
          - The response to the `$questionnaire-package` operation conforms to the [Questionnaire Package
            operation definition](https://hl7.org/fhir/us/davinci-dtr/STU2/OperationDefinition-questionnaire-package.html).
          - Each user-provided Questionnaire resource included in a `$next-question` response is valid
            and appropriate for the workflow.

        ### Must Support

        Each profile contains elements marked as "must support". Inferno expects to see each of
        these elements at least once. If at least one cannot be found, the test will skip.
        The test will look through the Questionnaire resources provided for these elements.
      )
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

      # Test 1: Recieve questionnaire-package and next-question requests
      test from: :dtr_smart_app_ms_adative_request
      # Test 2: validate the $questionnaire-package request body
      test from: :dtr_qp_request_validation
      # Test 3: validate the $next-question requests body
      test from: :dtr_adaptive_next_question_request_validation
      # Test 4: validate the QuestionnaireResponse in the input parameter
      test from: :dtr_adaptive_response_validation do
        description %(
          Verify that all submitted QuestionnaireResponse resources meet the following criteria:
          - Conform to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
          - Include source extensions indicating whether answers were manually entered,
            automatically pre-populated, or manually overridden (for `completed` QuestionnaireResponse).
          - Provide answers for all required items in their contained Questionnaire.
        )
        input :custom_next_question_questionnaires
      end
      # Test 5: validate the user provided $questionnaire-package response
      test from: :dtr_custom_qp_validation
      # Test 6: validate the user provided $next-question questionnaires
      test from: :dtr_custom_next_questionnaire_validation
      # Test 7: must support test
      test from: :dtr_questionnaire_must_support do
        title %(
          [USER INPUT VALIDATION] All must support elements are provided in the adaptive
          Questionnaire resources provided
        )
        description <<~DESCRIPTION
          The DTR client SHALL be able to handle all `mustSupport` elements defined in the
          [DTR Questionnaire for adaptive form](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt)
          profile. This test will look through the provided Questionnaire resources for the following
          must support elements:

          #{ADAPTIVE_QUESTIONNAIRE.map { |el| "- #{el}" }.join("\n")}
        DESCRIPTION

        input :custom_next_question_questionnaires
      end
      # Test 8: attest client system can handle `mustSupport` elements
      test from: :dtr_must_support_attest
    end
  end
end
