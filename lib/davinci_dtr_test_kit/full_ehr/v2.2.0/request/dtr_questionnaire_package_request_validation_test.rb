require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnairePackageRequestValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper

    id :dtr_full_ehr_v220_qp_request_validation
    title 'Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-input-parameters.html)
      structure.

      The test verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
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

        input_params = parse_fhir_request_entity(qp_request.request_body, 'Request', request_index)
        unless input_params.present?
          add_request_message(
            'error',
            'Request does not contain a recognized FHIR resource',
            request_index
          )
          next
        end
        unless input_params.is_a?(FHIR::Parameters)
          add_request_message(
            'error',
            'Request is not FHIR Parameters resource',
            request_index
          )
          next
        end

        resource_is_valid?(resource: input_params,
                           profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.2.0',
                           message_prefix: request_prefix(request_index))
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $questionnaire-package request(s). See Messages for details."
      )
    end
  end
end
