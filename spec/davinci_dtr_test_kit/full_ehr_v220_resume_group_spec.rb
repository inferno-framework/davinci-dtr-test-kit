require 'davinci_dtr_test_kit/full_ehr/v2.2.0/resume/dtr_full_ehr_workflow_resume_group'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowResume do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:client_id) { 'resume_group_spec_client_id' }
  let(:inputs) { { client_id: } }
  let(:initial_wait) { resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait') }
  let(:relaunch_wait) { resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait') }

  def resume_wait(test_suffix)
    Inferno::Repositories::Tests.new.all.find { |test| test.id.to_s.end_with?(test_suffix) }
  end

  def short_ids(runnables)
    runnables.map { |runnable| runnable.id.to_s.split('-').last }
  end

  it 'has no tester-provided Questionnaire input' do
    expect(described_class.available_inputs.keys.map(&:to_s).grep(/template/)).to be_empty
  end

  it 'extends the adaptive group with a second wait before the verification tests and a Resume group' do
    expect(described_class.superclass).to eq(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive)
    expect(short_ids(described_class.groups.first.children))
      .to eq(%w[dtr_full_ehr_v220_resume_initial_interaction_wait
                dtr_full_ehr_v220_resume_relaunch_interaction_wait
                dtr_full_ehr_v220_ui_display_and_interaction
                dtr_full_ehr_v220_adaptive_questionnaires_completed])
    resume_group = described_class.groups.find { |group| group.title == 'Resume' }
    expect(short_ids(resume_group.children))
      .to eq(%w[dtr_full_ehr_v220_resume_answer_sequence dtr_full_ehr_v220_qp_changedsince])
  end

  it 'leaves the abstract adaptive group with its one wait test' do
    expect(short_ids(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive.groups.first.children))
      .to eq(%w[dtr_full_ehr_v220_interaction_wait
                dtr_full_ehr_v220_ui_display_and_interaction
                dtr_full_ehr_v220_adaptive_questionnaires_completed])
  end

  it 'lets the resumed $questionnaire-package request through instead of limiting the scenario to one package' do
    expect(described_class.config.options[:qp_single_use]).to be_falsey
  end

  it 'tells the tester to save the Questionnaire after question 1 during the first wait' do
    result = run(initial_wait, inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include("In this first step, do **not** complete\nthe Questionnaire:\n" \
                                             "- Launch DTR.\n" \
                                             "- Answer question 1 and continue the form to get the second question.\n" \
                                             '- Without answering question 2, save the draft response and close ' \
                                             'the DTR session.')
    expect(result.result_message).to include('I attest that question 1 was answered and the in-progress response ' \
                                             'was saved without an answer to question 2, and the DTR session was ' \
                                             'closed.')
    expect(result.result_message).to_not include('completed and saved to the EHR')
  end

  it 'tells the tester to relaunch and answer questions 2 and 3 during the second wait' do
    result = run(relaunch_wait, inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message)
      .to include('- Relaunch DTR from the in-progress Questionnaire saved during the previous')
    expect(result.result_message).to include("- Answer question 2 and continue the form to get question 3.\n" \
                                             "- Answer question 3 and continue the form to complete it.\n" \
                                             '- Save the completed form.')
    expect(result.result_message).to include('I attest that DTR relaunched with the answer to question 1 restored, ' \
                                             'and the Questionnaire was completed and saved to the EHR.')
  end

  it 'offers true and false links in both waits' do
    [initial_wait, relaunch_wait].each do |wait_test|
      result = run(wait_test, inputs)

      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_pass\?token=#{client_id}\) if the above statement is \*\*true\*\*\.})
      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_fail\?token=#{client_id}\) if the above statement is \*\*false\*\*\.})
    end
  end

  it 'skips the second wait when the tester attested false to the first' do
    repo_create(:result, test_session_id: test_session.id, runnable: initial_wait.reference_hash, result: 'fail')

    result = run(relaunch_wait, inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message)
      .to include("the previous step, 'Retrieve, partially complete, and save a Questionnaire', was not completed")
  end

  it 'waits in the second wait when the tester attested true to the first' do
    repo_create(:result, test_session_id: test_session.id, runnable: initial_wait.reference_hash, result: 'pass')

    expect(run(relaunch_wait, inputs).result).to eq('wait')
  end

  it 'describes each wait with its own step instead of completing the Questionnaire' do
    expect(initial_wait.description).to include('answers question 1, and saves the in-progress')
    expect(relaunch_wait.description).to include('relaunches DTR from the saved')
    [initial_wait, relaunch_wait].each do |wait_test|
      expect(wait_test.description).to_not include('completes the questionnaire')
    end
  end

  it 'tags the requests of each wait so the two waits can be told apart' do
    expect(initial_wait.config.options[:dtr_sub_workflow_tag])
      .to eq(DaVinciDTRTestKit::RESUME_BEFORE_PAUSE_TAG)
    expect(relaunch_wait.config.options[:dtr_sub_workflow_tag])
      .to eq(DaVinciDTRTestKit::RESUME_AFTER_PAUSE_TAG)
    expect(initial_wait.config.options[:dtr_workflow_tag]).to eq('resume')
  end
end
