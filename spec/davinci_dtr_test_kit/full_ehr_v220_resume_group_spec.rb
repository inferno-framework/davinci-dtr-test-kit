require 'davinci_dtr_test_kit/full_ehr/v2.2.0/resume/dtr_full_ehr_workflow_resume_group'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowResume do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:client_id) { 'resume_group_spec_client_id' }
  let(:inputs) { { client_id: } }

  def resume_wait(test_suffix)
    Inferno::Repositories::Tests.new.all.find { |test| test.id.to_s.end_with?(test_suffix) }
  end

  it 'has no tester-provided Questionnaire input' do
    expect(described_class.available_inputs.keys.map(&:to_s).grep(/template/)).to be_empty
  end

  it 'tells the tester to save the Questionnaire after question 1 during the first wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include("In this first step, do **not** complete\nthe Questionnaire:\n" \
                                             "- Launch DTR and retrieve Inferno's Resume Questionnaire.")
    expect(result.result_message)
      .to include("- Without answering question 2, save the QuestionnaireResponse with status `in-progress`\n  " \
                  'and close the DTR session. The answer to question 1 must not be lost.')
    expect(result.result_message).to match(%r{\[click here\]\(\S+/resume_pass\?token=#{client_id}\) to continue})
    expect(result.result_message).to_not include('completed and saved to the EHR')
  end

  it 'tells the tester to relaunch and answer questions 2 and 3 during the second wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message)
      .to include('- Relaunch DTR from the in-progress QuestionnaireResponse saved during the previous')
    expect(result.result_message).to include('The answer to question 1 should be restored.')
    expect(result.result_message).to include("- Answer question 2 to get question 3, then answer question 3.\n" \
                                             '- Save the completed QuestionnaireResponse.')
    expect(result.result_message).to match(%r{\[click here\]\(\S+/resume_pass\?token=#{client_id}\)\nto continue})
    expect(result.result_message).to_not include('completed and saved to the EHR')
  end

  it 'describes each wait with its own step instead of completing the Questionnaire' do
    initial = resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait')
    relaunch = resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait')

    expect(initial.description).to include('answers question 1, and saves the in-progress')
    expect(relaunch.description).to include('relaunches DTR from the saved')
    [initial, relaunch].each do |wait_test|
      expect(wait_test.description).to_not include('completes the questionnaire')
    end
  end

  it 'tags the requests of each wait so the two waits can be told apart' do
    initial = resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait')
    relaunch = resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait')

    expect(initial.config.options[:dtr_interaction_tag])
      .to eq(DaVinciDTRTestKit::DTRFullEHRV220ResumeAnswerSequenceTest::BEFORE_PAUSE_TAG)
    expect(relaunch.config.options[:dtr_interaction_tag])
      .to eq(DaVinciDTRTestKit::DTRFullEHRV220ResumeAnswerSequenceTest::AFTER_PAUSE_TAG)
    expect(initial.config.options[:dtr_workflow_tag]).to eq('resume')
  end
end
