require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionRequestValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper

    id :dtr_full_ehr_v220_nq_request_validation
    title 'Next Question request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Next Question Input Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-next-question-input-parameters.html)
      structure. Because there is only a single in parameter, the request is allowed to be just a
      [DTR Questionnaire Response for adaptive form](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)

      The test verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      requests.each_with_index do |qp_request, request_index|
        unless qp_request.url == next_url
          add_request_message(
            'error',
            "Request made to wrong URL: #{qp_request.url}. Should instead be to #{next_url}.",
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

        if input_params.is_a?(FHIR::QuestionnaireResponse)
          resource_is_valid?(resource: input_params,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0',
                             message_prefix: request_prefix(request_index))

        elsif input_params.is_a?(FHIR::Parameters)
          resource_is_valid?(resource: input_params,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-input-parameters|2.2.0',
                             message_prefix: request_prefix(request_index))
        else
          add_request_message(
            'error',
            'Request is not FHIR Parameters resource',
            request_index
          )
        end
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $next-question request(s). See Messages for details."
      )
    end
  end
end
