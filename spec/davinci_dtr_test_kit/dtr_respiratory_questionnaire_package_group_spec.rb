RSpec.describe DaVinciDTRTestKit::DTRRespiratoryQuestionnairePackageGroup, :request do
  def app
    Inferno::Web.app
  end

  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_resp_qp') }
  let(:suite_id) { :dtr_smart_app }
  let(:questionnaire_package_url) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }

  describe 'Behavior of questionnaire package request test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'dtr_resp_qp_request' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:client_id) { '1234' }
    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?client_id=#{client_id}" }

    it 'passes if questionnaire package request is received' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:fhir_base_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return(''))

      result = run(runnable, client_id:, smart_app_launch: 'ehr')
      expect(result.result).to eq('wait')

      encoded_client_id = Base64.strict_encode64("{\"inferno_client_id\":\"#{client_id}\"}").delete('=')
      header 'Authorization',
             "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.#{encoded_client_id}"
      post(questionnaire_package_url, request_body)
      expect(last_response.ok?).to be(true)
      get(resume_pass_url)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end

  describe 'Behavior of questionnaire package request validation test' do
    let(:runnable) do
      group.tests.find do |test|
        test.id.to_s.end_with? 'dtr_qp_request_validation'
      end
    end
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end

    it 'passes if questionnaire package input parameters are conformant' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_package_url).and_return(questionnaire_package_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)

      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, name: 'questionnaire_package', url: questionnaire_package_url,
                            request_body:, test_session_id: test_session.id,
                            tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])

      result = run(runnable)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails if questionnaire package input parameters are nonconformant' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_package_url).and_return(questionnaire_package_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(false)

      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, request_body:, test_session_id: test_session.id,
                            tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])

      result = run(runnable)
      expect(result.result).to eq('fail')
    end
  end
end
