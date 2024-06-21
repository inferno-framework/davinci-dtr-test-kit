require_relative 'shared_setup'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup do
  include Rack::Test::Methods
  include_context('when running standard tests',
                  'payer_server_static_package',
                  suite_id = :dtr_payer_server,
                  questionnaire_package_url = "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package",
                  url = 'http://example.org/fhir/R4')

  describe 'Questionnaire package incoming request test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'questionnaire_request_test' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:retrieval_method) { 'static' }
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:access_token) { '1234' }
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
end
