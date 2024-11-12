require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRAdaptiveQuestionnaireNextQuestionRequestValidationTest < Inferno::Test
    include URLs

    id :dtr_next_question_request_validation
    title '$next-question request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [SDC Next Question Input Parameters](http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values.
    )

    def assert_valid_resource_type(resource)
      type = resource.resourceType
      valid = ['Parameters', 'QuestionnaireResponse'].include?(type)
      assert valid, "Request body not valid. Expected Parameters or QuestionnaireResponse, got #{type}"
    end

    run do
      load_tagged_requests CLIENT_NEXT_TAG
      skip_if request.blank?, 'A $next-question request must be made prior to running this test'

      assert request.url == next_url, "Request made to wrong URL: #{request.url}. Should instead be to #{next_url}"
      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      assert input_params.present?, 'Request does not contain a recognized FHIR object'
      assert_valid_resource_type(input_params)

      if input_params.is_a?(FHIR::Parameters)
        assert_valid_resource(
          resource: input_params,
          profile_url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in'
        )
        questionnaire_response_params = input_params.parameter.select { |param| param.name == 'questionnaire-response' }
        qr_params_count = questionnaire_response_params.length
        assert qr_params_count == 1,
               "Input parameter must contain one `parameter:questionnaire-response` slice. Found #{qr_params_count}"

        questionnaire_response =  questionnaire_response_params.first.resource
        assert_resource_type(:questionnaire_response, resource: questionnaire_response)
      else
        assert_valid_resource(
          resource: input_params,
          profile_url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
        )
      end
    end
  end
end
