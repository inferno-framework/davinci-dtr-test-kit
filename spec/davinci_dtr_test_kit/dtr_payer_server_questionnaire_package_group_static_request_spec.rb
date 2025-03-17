require_relative 'shared_setup'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup, :request do
  let(:suite_id) { 'dtr_payer_server' }
  include_context('when running standard tests',
                  'payer_server_static_package', # group
                  suite_id = :dtr_payer_server,
                  "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package", # questionnaire_package_url
                  'Static', # retrieval_method
                  'http://example.org/fhir/R4') # url

  context 'when initial request/response is manually provided' do
    let(:initial_static_questionnaire_request) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end

    describe 'static questionnaire package incoming request test' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'request_test' } }

      it 'passes if valid questionnaire request is manually provided' do
        result = run(runnable, test_session, access_token:,
                                             retrieval_method:, initial_static_questionnaire_request:, url:)
        expect(result.result).to eq('pass'), result.result_message
      end

      it 'skips if access token is nil' do
        result = run(runnable, test_session, retrieval_method:, initial_static_questionnaire_request:, url:)
        expect(result.result).to eq('skip'), result.result_message
      end
    end

    describe 'static Questionnaire request validation' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_request_validation_test' } }
      let(:input_validation_test) do
        Class.new(Inferno::Test) do
          def self.suite
            Inferno::Repositories::TestSuites.new.find('dtr_payer_server')
          end

          validator do
            url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
          end

          input :url, :access_token, :retrieval_method, :initial_static_questionnaire_request

          run do
            resource_is_valid?(resource:, profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1')
            errors_found = messages.any? { |message| message[:type] == 'error' }
            skip_if errors_found, 'Resource does not conform to the profile http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'
          end
        end
      end

      it 'passes if questionnaire request is conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::PayerStaticFormRequestValidationTest).to(
          receive(:resource_is_valid?).and_return(true)
        )

        stub_request(:post, validation_url)
          .with(query: {
                  profile: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        result = run(runnable, test_session, access_token:, retrieval_method:, initial_static_questionnaire_request:)
        expect(result.result).to eq('pass'), result.result_message
      end

      describe 'invalid request passed manually' do
        let(:initial_static_questionnaire_request) do
          File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_non_conformant.json'))
        end

        before do
          Inferno::Repositories::Tests.new.insert(input_validation_test)
        end

        it 'skips if questionnaire request is not conformant' do
          result = run(input_validation_test, test_session, access_token:, retrieval_method:,
                                                            initial_static_questionnaire_request:)
          expect(result.result).to eq('skip'), result.result_message
        end
      end
    end

    # all static tests should skip when flow is marked 'adaptive'
    context 'when retrieval method is adaptive' do
      let(:retrieval_method) { 'Adaptive' }

      describe 'static questionnaire package incoming request test' do
        let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'request_test' } }
        let(:results_repo) { Inferno::Repositories::Results.new }

        it 'skips when retrieval method is adaptive' do
          result = run(runnable, test_session, access_token:, retrieval_method:, url:)
          expect(result.result).to eq('skip')
        end
      end

      describe 'static questionnaire package request validation test' do
        let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_request_validation_test' } }
        let(:results_repo) { Inferno::Repositories::Results.new }

        it 'skips when retrieval method is adaptive' do
          result = run(runnable, test_session, access_token:, retrieval_method:, initial_static_questionnaire_request:)
          expect(result.result).to eq('skip')
        end
      end
    end
  end

  # When initial request is not provided i.e. client flow
  describe 'static questionnaire package incoming request test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'request_test' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:request_body_conformant) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:request_body_non_conformant) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_non_conformant.json'))
    end

    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?token=#{access_token}" }

    it 'passes if questionnaire package request is received' do
      stub_request(:post, "#{url}/Questionnaire/$questionnaire-package")
        .to_return(status: 200, body: '', headers: {})

      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:fhir_base_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return(''))

      result = run(runnable, test_session, access_token:, retrieval_method:, url:)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_package_url, request_body_conformant)
      expect(last_response.ok?).to be(true)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    describe 'static questionnaire package request validation test' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_request_validation_test' } }
      let(:results_repo) { Inferno::Repositories::Results.new }

      it 'skips when access_token is nil' do
        result = run(runnable, test_session, retrieval_method:)
        expect(result.result).to eq('skip'), result.result_message
      end

      it 'passes when client request is conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(
                                                            questionnaire_package_url
                                                          ))

        result = repo_create(:result, test_session_id: test_session.id)
        repo_create(:request, result_id: result.id, name: 'questionnaire_package', url: questionnaire_package_url,
                              request_body: request_body_conformant, test_session_id: test_session.id,
                              tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])

        allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
        result = run(runnable, test_session, access_token:, retrieval_method:)
        expect(result.result).to eq('pass'), result.result_message
      end

      it 'skips when client request is not conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(
                                                            questionnaire_package_url
                                                          ))

        result = repo_create(:result, test_session_id: test_session.id)
        repo_create(:request, result_id: result.id, name: 'questionnaire_package', url: questionnaire_package_url,
                              request_body: request_body_non_conformant, test_session_id: test_session.id,
                              tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])

        runnable.validator do
          url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
        end

        stub_request(:post, validation_url)
          .with(query: {
                  profile: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new(issue: { severity: 'error' }).to_json)

        result = run(runnable, test_session, access_token:, retrieval_method:)
        expect(result.result).to eq('skip'), result.result_message
      end
    end
  end
end
