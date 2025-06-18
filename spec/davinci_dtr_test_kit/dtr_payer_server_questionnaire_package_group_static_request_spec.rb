RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup, :request do
  let(:suite_id) { 'dtr_payer_server' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:url) { 'https://example.com/fhir/R4' }
  let(:access_token) { 'dummy' }
  let(:questionnaire_package_url) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:profile_url) { 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1' }

  context 'when initial request/response is manually provided' do
    let(:retrieval_method) { 'Static' }
    let(:initial_static_questionnaire_request) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end

    describe 'static questionnaire package incoming request test' do
      let(:runnable) { find_test suite, 'request_test' }

      it 'passes if valid questionnaire request is manually provided' do
        result = run(runnable, { url:, access_token:, retrieval_method:, initial_static_questionnaire_request: })
        expect(result.result).to eq('pass'), result.result_message
      end

      it 'skips if access token is nil' do
        result = run(runnable, { url:, retrieval_method: })
        expect(result.result).to eq('skip'), result.result_message
      end
    end

    describe 'static questionnaire request validation' do
      let(:runnable) { find_test suite, 'static_form_request_validation_test' }
      let(:retrieval_method) { 'Static' }

      it 'passes if questionnaire request is conformant' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        stub_request(:post, validation_url)
          .with(query: {
                  profile: profile_url
                })
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        result = run(runnable, { url:, access_token:, retrieval_method:, initial_static_questionnaire_request: })
        expect(result.result).to eq('pass'), result.result_message
      end

      describe 'invalid request passed manually' do
        let(:bad_static_questionnaire_request) do
          File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_non_conformant.json'))
        end

        # before do
        #   Inferno::Repositories::Tests.new.insert(input_validation_test)
        # end

        it 'skips if questionnaire request is not conformant' do
          stub_request(:post, validation_url)
            .to_return(status: 200, body: FHIR::OperationOutcome.new(
                         issue: [
                           FHIR::OperationOutcome::Issue.new(
                             severity: 'error',
                             code: 'invalid',
                             details: FHIR::CodeableConcept.new(
                               text: "Resource is not conformant to profile #{profile_url}"
                             )
                           )
                         ]
                       ).to_json
            )

          result = run(runnable,
                       { url:, access_token:, retrieval_method:, initial_static_questionnaire_request: bad_static_questionnaire_request })
          expect(result.result).to eq('skip'), result.result_message
        end
      end
    end

    # all static tests should skip when flow is marked 'adaptive'
    context 'when retrieval method is adaptive' do
      let(:retrieval_method) { 'Adaptive' }

      describe 'static questionnaire package incoming request test' do
        let(:runnable) { find_test described_class, 'request_test' }
        let(:results_repo) { Inferno::Repositories::Results.new }

        it 'skips when retrieval method is adaptive' do
          result = run(runnable, { url:, access_token:, retrieval_method: })
          expect(result.result).to eq('skip')
        end
      end

      describe 'static questionnaire package request validation test' do
        let(:runnable) { find_test described_class, 'static_form_request_validation_test' }

        it 'skips when retrieval method is adaptive' do
          result = run(runnable, { access_token:, retrieval_method: })
          expect(result.result).to eq('skip')
        end
      end
    end
  end

  # When initial request is not provided i.e. client flow
  describe 'static questionnaire package incoming request test' do
    let(:runnable) { find_test described_class, 'request_test' }
    let(:retrieval_method) { 'Static' }
    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?token=#{access_token}" }
    let(:request_body_conformant) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:request_body_non_conformant) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_non_conformant.json'))
    end

    it 'passes if questionnaire package request is received' do
      stub_request(:post, "#{url}/Questionnaire/$questionnaire-package")
        .to_return(status: 200, body: '', headers: {})

      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:fhir_base_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return(''))

      result = run(runnable, { url:, access_token:, retrieval_method: })
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_package_url, request_body_conformant)
      expect(last_response.ok?).to be(true)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    describe 'static questionnaire package request validation test' do
      let(:runnable) { find_test described_class, 'static_form_request_validation_test' }
      let(:retrieval_method) { 'Static' }

      it 'skips when access_token is nil' do
        result = run(runnable, { retrieval_method: })
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
        result = run(runnable, { access_token:, retrieval_method: })
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

        result = run(runnable, { access_token:, retrieval_method: })
        expect(result.result).to eq('skip'), result.result_message
      end
    end
  end
end
