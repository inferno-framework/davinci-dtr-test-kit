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

  it 'extends the adaptive group with a second wait before the verification tests and a Resume group' do
    expect(described_class.superclass).to eq(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive)
    interaction_ids = described_class.interaction_group.all_children.map { |test| test.id.to_s.split('-').last }
    expect(interaction_ids).to eq(%w[dtr_full_ehr_v220_resume_initial_interaction_wait
                                     dtr_full_ehr_v220_resume_relaunch_interaction_wait
                                     dtr_full_ehr_v220_ui_display_and_interaction
                                     dtr_full_ehr_v220_adaptive_questionnaires_completed])
    resume_group = described_class.all_children.find { |group| group.title == 'Resume' }
    expect(resume_group.all_children.map { |test| test.id.to_s.split('-').last })
      .to eq(%w[dtr_full_ehr_v220_resume_answer_sequence dtr_full_ehr_v220_qp_changedsince])
  end

  it 'leaves the abstract adaptive group with one wait test' do
    expect(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive.interaction_wait_tests.length).to eq(1)
  end

  it 'tells the tester to save the Questionnaire after question 1 during the first wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include("In this first step, do **not** complete\nthe Questionnaire:\n" \
                                             "- Launch DTR.\n" \
                                             "- Answer question 1 and continue the form to get the second question.\n" \
                                             '- Without answering question 2, save the draft response and close ' \
                                             'the DTR session.')
    expect(result.result_message).to include('When the in-progress response is saved and the DTR session is closed,')
    expect(result.result_message).to match(%r{\[click here\]\(\S+/resume_pass\?token=#{client_id}\) to continue})
    expect(result.result_message).to include('The Questionnaire will be resumed')
    expect(result.result_message).to_not include('completed and saved to the EHR')
  end

  it 'tells the tester to relaunch and answer questions 2 and 3 during the second wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message)
      .to include('- Relaunch DTR from the in-progress Questionnaire saved during the previous')
    expect(result.result_message).to include("- Answer question 2 and continue the form to get question 3.\n" \
                                             "- Answer question 3 and continue the form to complete it.\n" \
                                             '- Save the completed form.')
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

    expect(initial.config.options[:dtr_sub_workflow_tag])
      .to eq(DaVinciDTRTestKit::RESUME_BEFORE_PAUSE_TAG)
    expect(relaunch.config.options[:dtr_sub_workflow_tag])
      .to eq(DaVinciDTRTestKit::RESUME_AFTER_PAUSE_TAG)
    expect(initial.config.options[:dtr_workflow_tag]).to eq('resume')
  end
end
