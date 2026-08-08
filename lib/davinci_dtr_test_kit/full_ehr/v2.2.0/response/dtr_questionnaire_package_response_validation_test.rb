require_relative '../../../urls'
require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../short_circuit_interaction_verification'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnairePackageResponseValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include ShortCircuitInteractionVerification

    id :dtr_full_ehr_v220_qp_response_validation
    title 'Questionnaire Package response is valid'
    description %(
      This test validates the conformance of the Inferno's simulated response to the
      [DTR Questionnaire Package Output Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-output-parameters.html)
      structure.

      The test verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    simulation_verification

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])

      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A Questionnaire Package request must be made prior to running this test'

      requests.each_with_index do |qp_request, request_index|
        unless qp_request.url == questionnaire_package_url
          add_request_message(
            'error',
            "Request made to wrong URL: #{qp_request.url}. Should instead be to #{questionnaire_package_url}.",
            request_index
          )
        end

        output_params = parse_fhir_request_entity(qp_request.response_body, 'Response', request_index)
        unless output_params.present?
          add_request_message(
            'error',
            'Response does not contain a recognized FHIR resource',
            request_index
          )
          next
        end
        unless output_params.is_a?(FHIR::Parameters)
          add_request_message(
            'error',
            'Response is not FHIR Parameters resource',
            request_index
          )
          next
        end

        resource_is_valid?(resource: output_params,
                           profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.2.0',
                           message_prefix: request_prefix(request_index))
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $questionnaire-package response(s). See Messages for details."
      )
    end
  end
end
