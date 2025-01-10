RSpec.describe DaVinciDTRTestKit::DTRFullEHRQuestionnaireResponseCorrectnessTest do
  let(:suite_id) { :dtr_full_ehr }
  # let(:runnable) { Inferno::Repositories::Tests.new.find('dtr_full_ehr_questionnaire_response_correctness') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:runnable) do
    Class.new(described_class) do
      input :questionnaire_response, optional: true
    end
  end
  let(:custom_questionnaire_package_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_package.json'))
  end
  let(:questionnaire_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_response_conformant.json'))
  end
  let(:bad_questionnaire_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_response_missing_answers.json'))
  end

  def run(runnable, test_session, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  it 'passes if all required questions are answered and all questionnaire response items have an origin.source' do
    result = run(runnable, test_session, questionnaire_response:, custom_questionnaire_package_response:)
    expect(result.result).to eq('pass'), result.result_message
  end

  it 'skips if no questionnaire_response provided for validation' do
    result = run(runnable, test_session)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/QuestionnaireResponse input was blank/)
  end

  it 'skips if the questionnaire referenced in the QR is not in the provided custom package response' do
    result = run(
      runnable, test_session, questionnaire_response:, custom_questionnaire_package_response: FHIR::Bundle.new.to_json
    )
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Couldn't find Questionnaire/)
  end

  it 'fails if a required answer is missing or all QR items do not have an origin.source' do
    result = run(
      runnable, test_session, questionnaire_response: bad_questionnaire_response, custom_questionnaire_package_response:
    )
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/QuestionnaireResponse is not correct/)
  end
end
