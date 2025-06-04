RSpec.describe DaVinciDTRTestKit::DTRFullEHRAdaptiveInitialRetrievalGroup, :request do
  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_full_ehr_adaptive_initial_retrieval') }
  let(:suite_id) { :dtr_full_ehr }
  let(:questionnaire_package_url) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:next_url) { "/custom/#{suite_id}/fhir/Questionnaire/$next-question" }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:client_id) { 'sample_id' }
  let(:next_question_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_conformant.json'))
  end
  let(:next_question_request_body_nonconformant) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_nonconformant.json'))
  end
  let(:next_tag) { "initial#{DaVinciDTRTestKit::CLIENT_NEXT_TAG}" }

  def build_next_request(request_body)
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, url: next_url, request_body:,
                          test_session_id: test_session.id, tags: [next_tag])
  end

  describe 'questionnaire package request and initial next question request test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'dtr_full_ehr_adaptive_request' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:package_request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?token=#{client_id}" }

    it 'passes if questionnaire package and next question requests are received' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:next_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return(''))

      result = run(runnable, test_session, client_id:)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}"
      post(questionnaire_package_url, package_request_body)
      expect(last_response.ok?).to be(true)
      post(next_url, package_request_body)
      expect(last_response.ok?).to be(true)

      get(resume_pass_url)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end

  describe 'next question request validation test' do
    let(:runnable) do
      group.tests.find do |test|
        test.id.to_s.end_with? 'dtr_adaptive_next_question_request_validation'
      end
    end

    before do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:next_url).and_return(next_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)
      allow_any_instance_of(runnable).to receive(:next_request_tag).and_return(next_tag)
    end

    it 'passes if next question input parameters are conformant' do
      build_next_request(next_question_request_body)

      result = run(runnable, test_session)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'skips if no next-question request was made' do
      result = run(runnable, test_session)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/next-question request must be made prior to running this test/)
    end

    it 'fails if next question request body is not a valid json' do
      build_next_request('[[')

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/Invalid JSON/)
    end

    it 'fails if next question request body is not a valid FHIR object' do
      build_next_request({}.to_json)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/does not contain a recognized FHIR object/)
    end

    it 'fails if next question request body is not a Parameters resource' do
      build_next_request({ resourceType: 'Patient' }.to_json)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/Expected Parameters or QuestionnaireResponse/)
    end

    it 'fails if next question input parameters resource does not have a questionnaire-response param' do
      build_next_request(next_question_request_body_nonconformant)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/must contain one `parameter:questionnaire-response` slice/)
    end

    it 'fails if the resource for the questionnaire-response param is not QuestionnaireResponse' do
      param = FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: FHIR::Patient.new)
      build_next_request(FHIR::Parameters.new(parameter: [param]).to_json)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/Unexpected resource type: expected QuestionnaireResponse/)
    end
  end

  describe 'adaptive questionnaire response validation test' do
    let(:runnable) do
      group.tests.find do |test|
        test.id.to_s.end_with? 'dtr_adaptive_response_validation'
      end
    end

    before do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:next_url).and_return(next_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)
      allow_any_instance_of(runnable).to receive(:next_request_tag).and_return(next_tag)
    end

    it 'skips if no next-question request was made' do
      result = run(runnable, test_session)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/next-question request must be made prior to running this test/)
    end

    it 'fails if next question request body is not a valid json' do
      build_next_request('[[')

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/Invalid JSON/)
    end

    it 'fails if next question request body is not a valid FHIR object' do
      build_next_request({}.to_json)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/does not contain a recognized FHIR object/)
    end

    it 'fails if next question input parameters resource does not have questionnaire-response param slice' do
      build_next_request(next_question_request_body_nonconformant)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/QuestionnaireResponse resource not provided/)
    end

    it 'fails if the answers in the questionnaire response do not have the correct origin.source' do
      request_body = File.read(File.join(__dir__, '..', 'fixtures',
                                         'next_question_input_params_no_origin_extension.json'))
      build_next_request(request_body)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/Required `origin.source` extension not present on answer/)
    end

    it 'fails if a required answer is missing from the questionnaire response' do
      request_body = File.read(File.join(__dir__, '..', 'fixtures',
                                         'next_question_input_params_missing_answer.json'))
      build_next_request(request_body)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join
      expect(result_messages_string).to match(/No answer for item/)
    end
  end
end
