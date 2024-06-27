require_relative 'shared_setup'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup do
  include Rack::Test::Methods
  include_context('when running standard tests',
                  'payer_server_static_package', # group
                  suite_id = :dtr_payer_server,
                  "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package", # questionnaire_package_url
                  'Static', # retrieval_method
                  'http://example.org/fhir/R4') # url

  context 'when initial request is manually provided' do
    let(:initial_static_questionnaire_request) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_conformant.json'))
    end

    describe 'static questionnaire package incoming request test' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'questionnaire_request_test' } }

      it 'passes if questionnaire request is manually provided' do
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

      it 'passes if questionnaire request is conformant' do
        allow_any_instance_of(DaVinciDTRTestKit::PayerStaticFormRequestValidationTest).to(
          receive(:assert_valid_resource).and_return(true)
        )

        result = run(runnable, test_session, access_token:, retrieval_method:, initial_static_questionnaire_request:)
        expect(result.result).to eq('pass'), result.result_message
      end

      describe 'invalid request passed manually' do
        let(:initial_static_questionnaire_request) do
          File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_non_conformant.json'))
        end
        it 'skips if questionnaire request is not conformant' do
          allow_any_instance_of(DaVinciDTRTestKit::PayerStaticFormRequestValidationTest).to(
            receive(:assert_valid_resource).and_return(false)
          )

          result = run(runnable, test_session, access_token:, retrieval_method:, initial_static_questionnaire_request:)
          expect(result.result).to eq('skip'), result.result_message
        end
      end
    end

    # all static tests should skip when flow is marked 'adaptive'
    context 'when retrieval method is adaptive' do
      let(:retrieval_method) { 'Adaptive' }

      describe 'static questionnaire package incoming request test' do
        let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'questionnaire_request_test' } }
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
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'questionnaire_request_test' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end

    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?token=#{access_token}" }

    it 'passes if questionnaire package request is received' do
      stub_request(:post, "#{url}/Questionnaire/$questionnaire-package")
        .with(
          body: JSON.parse(request_body),
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Length' => '2082',
            'Content-Type' => 'application/json',
            'Host' => 'example.org',
            'User-Agent' => 'rest-client/2.1.0 (darwin22 arm64) ruby/3.1.2p20'
          }
        )
        .to_return(status: 200, body: '', headers: {})

      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:fhir_base_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return(''))

      result = run(runnable, test_session, access_token:, retrieval_method:, url:)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_package_url, request_body)
      expect(last_response.ok?).to be(true)

      get(resume_pass_url)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end

  describe 'static questionnaire package request validation test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_request_validation_test' } }
    let(:results_repo) { Inferno::Repositories::Results.new }

    it 'skips when access_token is nil' do
      result = run(runnable, test_session, retrieval_method:)
      expect(result.result).to eq('skip'), result.result_message
    end

    # it 'passes when client request is conformant' do
    #   allow_any_instance_of(runnable).to(receive(:perform_request_validation_test)).and_return(true)

    #   result = run(runnable, test_session, access_token:, retrieval_method:)
    #   expect(result.result).to eq('skip'), result.result_message
    # end

    # it 'skips when client request is not conformant' do
    #   allow_any_instance_of(runnable).to(receive(:perform_request_validation_test)).and_return(false)

    #   result = run(runnable, test_session, retrieval_method:)
    #   expect(result.result).to eq('skip'), result.result_message
    # end
  end
end
