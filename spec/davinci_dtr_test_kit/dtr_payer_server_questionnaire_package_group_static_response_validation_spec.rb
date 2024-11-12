require_relative 'shared_setup'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup do
  include Rack::Test::Methods
  include_context('when running standard tests',
                  'payer_server_static_package', # group
                  suite_id = :dtr_payer_server,
                  "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package", # questionnaire_package_url
                  'Static', # retrieval_method
                  'http://example.org/fhir/R4') # url

  let(:validation_url) { "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate" }

  context 'when initial request/response is manually provided' do
    let(:initial_static_questionnaire_request) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:output_params) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_output_params_conformant.json'))
    end
    let(:output_params_non_conformant) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_output_params_non_conformant.json'))
    end

    describe 'static response validation test' do
      let(:output_validation_test) do
        Class.new(Inferno::Test) do
          include DaVinciDTRTestKit::ValidationTest

          validator do
            url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
          end

          input :url, :access_token, :retrieval_method, :initial_static_questionnaire_request, :output_params

          def resource_type
            'Parameter'
          end

          run do
            request = Inferno::Entities::Request.new(response_body: output_params, status: 200)
            resource = FHIR.from_contents(request.response[:body])
            assert_response_status([200, 201], response: request.response)
            assert_resource_type(:parameters, resource:)
            perform_response_validation_test(
              [request],
              :parameters,
              'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.0.1'
            )
            questionnaire_bundle = resource.parameter.find { |param| param.resource.resourceType == 'Bundle' }&.resource
            assert questionnaire_bundle, 'No questionnaire bundle found in the response'
            assert_valid_resource(resource: questionnaire_bundle, profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.0.1')
            assert_resource_type(:bundle, resource: questionnaire_bundle)
          end
        end
      end

      before do
        Inferno::Repositories::Tests.new.insert(output_validation_test)
      end

      it 'passes if questionnaire response is conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::PayerStaticFormResponseTest).to(
          receive(:assert_valid_resource).and_return(true)
        )
        stub_request(:post, validation_url)
          .with(query: {
                  profile: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.0.1'
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        stub_request(:post, validation_url)
          .with(query: {
                  profile: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.0.1'
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)
        result = run(output_validation_test, test_session, url:, access_token:,
                                                           retrieval_method:,
                                                           initial_static_questionnaire_request:,
                                                           output_params:)
        expect(result.result).to eq('pass'), result.result_message
      end

      it 'fails if questionnaire response is not conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::PayerStaticFormResponseTest).to(
          receive(:assert_valid_resource).and_return(true)
        )
        stub_request(:post, validation_url)
          .with(query: {
                  profile: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.0.1'
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new(issue: { severity: 'error' }).to_json)

        result = run(output_validation_test, test_session, url:, access_token:, retrieval_method:,
                                                           initial_static_questionnaire_request:,
                                                           output_params: output_params_non_conformant)
        expect(result.result).to eq('fail'), result.result_message
      end
    end
  end
end
