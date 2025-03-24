require_relative '../../descriptions'
require_relative '../../urls'
require_relative '../../session_identification'

module DaVinciDTRTestKit
  class DTRAdaptiveNextQuestionRequestValidationTest < Inferno::Test
    include URLs
    include SessionIdentification

    id :dtr_adaptive_next_question_request_validation
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

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.

      The QuestionnaireResponse resource's structure and conformance will be validated
      in the following test ('Adaptive QuestionnaireResponse is valid').
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@264'

    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED
    input :session_url_path,
          title: 'Session-specific URL path extension',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_SESSION_URL_PATH_LOCKED

    def assert_valid_resource_type(resource)
      type = resource.resourceType
      valid = ['Parameters', 'QuestionnaireResponse'].include?(type)
      assert valid, "Request body not valid. Expected Parameters or QuestionnaireResponse, got #{type}"
    end

    def next_request_tag
      config.options[:next_tag]
    end

    def perform_requests_validation
      nq_endpoint = inputs_to_session_endpont(:next_question, client_id, session_url_path)

      requests.each_with_index do |r, index|
        if r.url != nq_endpoint
          add_message('warning',
                      "Request #{index} made to wrong URL: #{r.url}. Should instead be to #{nq_endpoint}")
        end
        assert_valid_json(r.request_body)
        input_params = FHIR.from_contents(r.request_body)
        assert input_params.present?, 'Request does not contain a recognized FHIR object'
        assert_valid_resource_type(input_params)

        if input_params.is_a?(FHIR::Parameters)
          questionnaire_response_params = input_params.parameter.select do |param|
            param.name == 'questionnaire-response'
          end
          qr_params_count = questionnaire_response_params.length
          assert qr_params_count == 1,
                 "Input parameter must contain one `parameter:questionnaire-response` slice. Found #{qr_params_count}"

          questionnaire_response =  questionnaire_response_params.first.resource
          assert_resource_type(:questionnaire_response, resource: questionnaire_response)
        end
      rescue Inferno::Exceptions::AssertionException => e
        add_message('error', "Request #{index}: #{e.message}")
        next
      end
    end

    run do
      load_tagged_requests next_request_tag
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      perform_requests_validation

      assert messages.none? { |m| m[:type] == 'error' }, 'next-quest request(s) not comformant'
    end
  end
end
