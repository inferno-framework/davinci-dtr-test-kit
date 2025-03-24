RSpec.describe DaVinciDTRTestKit::DTRFullEHRCustomAdaptiveWorkflowGroup, :request do
  let(:suite_id) { :dtr_full_ehr }
  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_full_ehr_custom_adaptive_workflow') }
  let(:access_token) { 'sample_token' }
  let(:questionnaire_package_url) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:next_url) { "/custom/#{suite_id}/fhir/Questionnaire/$next-question" }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:custom_questionnaires) do
    [
      FHIR::Questionnaire.new(id: 'DinnerOrderAdaptive', name: 'Questionnaire 1', status: 'draft'),
      FHIR::Questionnaire.new(id: 'DinnerOrderAdaptive', name: 'Questionnaire 2', status: 'draft'),
      FHIR::Questionnaire.new(id: 'DinnerOrderAdaptive', name: 'Questionnaire 3', status: 'draft')
    ]
  end
  let(:next_question_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_conformant.json'))
  end
  let(:next_tag) { "custom_#{DaVinciDTRTestKit::CLIENT_NEXT_TAG}" }

  def build_next_request(request_bodies)
    result = repo_create(:result, test_session_id: test_session.id)
    request_bodies.each do |request_body|
      repo_create(:request, result_id: result.id, url: next_url, request_body:,
                            test_session_id: test_session.id, tags: [next_tag])
    end
  end

  describe 'custom adaptive request test' do
    let(:runnable) { find_test(group, 'dtr_full_ehr_custom_adative_request') }
    let(:package_request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:adaptive_custom_questionnaire_package_response) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_output_params_conformant.json'))
    end
    let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass?token=#{access_token}" }

    before { allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:resume_pass_url).and_return('')) }

    it 'fails when an empty package response is provided' do
      result = run(runnable, access_token:, adaptive_custom_questionnaire_package_response: {}.to_json,
                             custom_next_question_questionnaires: custom_questionnaires.to_json)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Custom questionnaire package response is empty/)
    end

    it 'fails when an empty questionnaire list is provided' do
      result = run(runnable, access_token:, adaptive_custom_questionnaire_package_response:,
                             custom_next_question_questionnaires: [].to_json)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Custom questionnaires list is empty/)
    end

    it 'returns the user provided custom package to the questionnaire package request' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:questionnaire_package_url).and_return(''))
      result = run(runnable, access_token:, adaptive_custom_questionnaire_package_response:,
                             custom_next_question_questionnaires: custom_questionnaires.to_json)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_package_url, package_request_body)
      expect(last_response.ok?).to be(true)
      expect(parsed_body).to eq(JSON.parse(adaptive_custom_questionnaire_package_response))
    end

    it 'returns the expected Questionnaire for each next-question request' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(receive(:next_url).and_return(''))
      allow_any_instance_of(DaVinciDTRTestKit::MockPayer::NextQuestionEndpoint).to(
        receive(:evaluate_fhirpath).and_return([])
      )
      result = run(runnable, access_token:, adaptive_custom_questionnaire_package_response:,
                             custom_next_question_questionnaires: custom_questionnaires.to_json)
      expect(result.result).to eq('wait')
      header 'Authorization', "Bearer #{access_token}"
      post(next_url, next_question_request_body)
      expect(last_response.ok?).to be(true)
      contained_questionnaire = parsed_body['contained'].first
      expect(contained_questionnaire).to eq(custom_questionnaires.first.to_hash)

      post(next_url, next_question_request_body)
      expect(last_response.ok?).to be(true)
      contained_questionnaire = parsed_body['contained'].first
      expect(contained_questionnaire).to eq(custom_questionnaires.second.to_hash)

      post(next_url, next_question_request_body)
      expect(last_response.ok?).to be(true)
      contained_questionnaire = parsed_body['contained'].first
      expect(contained_questionnaire).to eq(custom_questionnaires.last.to_hash)

      post(next_url, next_question_request_body)
      expect(last_response.ok?).to be(true)
      expect(parsed_body['status']).to eq('completed')

      qr = JSON.parse(next_question_request_body)['parameter'].first['resource']
      request_body_questionnaire = qr['contained'].first
      contained_questionnaire = parsed_body['contained'].first
      expect(contained_questionnaire).to eq(request_body_questionnaire)
    end
  end

  describe 'custom adaptive questionnaire response validation test' do
    let(:runnable) { find_test(group, 'dtr_adaptive_response_validation') }

    before do
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)
      allow_any_instance_of(runnable).to receive(:next_request_tag).and_return(next_tag)
    end

    it 'fails if the required number of next-question requests have not been made' do
      build_next_request([next_question_request_body])
      result = run(runnable, custom_next_question_questionnaires: custom_questionnaires.to_json)
      expect(result.result).to eq('fail')

      expect(result.result_message).to match(/Workflow not completed/)
    end

    it 'fails if a next-question request does not contain the expected questionnaire' do
      questionnaire = custom_questionnaires.last
      questionnaire.item = [{ linkId: '3' }]
      qr_json = FHIR::QuestionnaireResponse.new(contained: [questionnaire]).to_json
      build_next_request([next_question_request_body, qr_json])
      result = run(runnable, custom_next_question_questionnaires: custom_questionnaires.to_json)
      expect(result.result).to eq('fail')
      result_messages_string = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages.map(&:message).join

      expect(result_messages_string).to match(/contained Questionnaire `item` does not match/)
    end
  end
end
