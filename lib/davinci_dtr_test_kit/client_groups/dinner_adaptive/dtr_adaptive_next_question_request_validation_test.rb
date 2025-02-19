require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRAdaptiveNextQuestionRequestValidationTest < Inferno::Test
    include URLs

    id :dtr_next_question_request_validation
    title '$next-question request is valid'
    description %(
      Per the [OperationDefinition: Adaptive questionnaire next question](https://build.fhir.org/ig/HL7/sdc/OperationDefinition-Questionnaire-next-question.html#root)
      section in the [Structured Data Capture IG](http://hl7.org/fhir/uv/sdc/ImplementationGuide/hl7.fhir.uv.sdc),
      the request body for the `$next-question` operation should be a FHIR Parameters resource containing a
      single parameter with:
        - name: `questionnaire-response`
        - resource: A `QuestionnaireResponse` resource

      As outlined in the [FHIR Operation Request](https://hl7.org/fhir/r4/operations.html#request) section of the
      FHIR specification, if an operation has exactly one input parameter of type Resource, it can also be invoked via
      a POST request using that resource as the body (with no additional URL parameters).

      This test validates the structure of the `$next-question` request body. It confirms that the body is either a
      Parameters resource or a QuestionnaireResponse resource.

      If it is a Parameters resource, it must contain one parameter named `questionnaire-response`
      with a `resource` attribute set to a FHIR QuestionnaireResponse instance, as specified above.

      The QuestionnaireResponse resource's structure and conformance will be validated
      in the following test ('Adaptive QuestionnaireResponse is valid').
    )

    def assert_valid_resource_type(resource)
      type = resource.resourceType
      valid = ['Parameters', 'QuestionnaireResponse'].include?(type)
      assert valid, "Request body not valid. Expected Parameters or QuestionnaireResponse, got #{type}"
    end

    def next_request_tag
      config.options[:next_tag]
    end

    run do
      load_tagged_requests next_request_tag
      skip_if request.blank?, 'A $next-question request must be made prior to running this test'

      assert request.url == next_url, "Request made to wrong URL: #{request.url}. Should instead be to #{next_url}"
      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      assert input_params.present?, 'Request does not contain a recognized FHIR object'
      assert_valid_resource_type(input_params)

      if input_params.is_a?(FHIR::Parameters)
        questionnaire_response_params = input_params.parameter.select { |param| param.name == 'questionnaire-response' }
        qr_params_count = questionnaire_response_params.length
        assert qr_params_count == 1,
               "Input parameter must contain one `parameter:questionnaire-response` slice. Found #{qr_params_count}"

        questionnaire_response =  questionnaire_response_params.first.resource
        assert_resource_type(:questionnaire_response, resource: questionnaire_response)
      end
    end
  end
end
