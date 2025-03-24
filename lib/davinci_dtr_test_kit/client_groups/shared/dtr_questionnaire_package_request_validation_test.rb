require_relative '../../descriptions'
require_relative '../../urls'
require_relative '../../session_identification'

module DaVinciDTRTestKit
  class DTRQuestionnairePackageValidationTest < Inferno::Test
    include URLs
    include SessionIdentification

    id :dtr_qp_request_validation
    title 'Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@168', 'hl7.fhir.us.davinci-dtr_2.0.1@293',
                          'hl7.fhir.us.davinci-dtr_2.0.1@295'

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

    def qp_tag
      config.options[:questionnaire_package_tag] || QUESTIONNAIRE_PACKAGE_TAG
    end

    run do
      load_tagged_requests qp_tag
      skip_if request.blank?, 'A Questionnaire Package request must be made prior to running this test'

      qp_endpoint = inputs_to_session_endpont(:questionnaire_package, client_id, session_url_path)
      assert request.url == qp_endpoint,
             "Request made to wrong URL: #{request.url}. Should instead be to #{qp_endpoint}."

      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      assert input_params.present?, 'Request does not contain a recognized FHIR object'
      assert_resource_type(:parameters, resource: input_params)
      assert_valid_resource(resource: input_params,
                            profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1')
    end
  end
end
