require 'davinci_dtr_test_kit/full_ehr/v2.2.0/workflows/dtr_full_ehr_workflow_resume_group'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowResume do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:client_id) { 'resume_group_spec_client_id' }
  let(:template) do
    File.read(File.join(__dir__, '..', '..', 'lib', 'davinci_dtr_test_kit', 'full_ehr', 'fixtures', 'resume',
                        'parameters_questionnaire_resume.json'))
  end
  let(:inputs) { { client_id:, resume_qp_response_template: template } }

  def resume_wait(test_suffix)
    Inferno::Repositories::Tests.new.all.find { |test| test.id.to_s.end_with?(test_suffix) }
  end

  it 'tells the tester to save the Questionnaire part-way through during the first wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include("In this first step, do **not** complete the Questionnaire:\n" \
                                             '- Answer some, but not all, of its questions.')
  end

  it 'tells the tester to relaunch from the saved QuestionnaireResponse during the second wait' do
    result = run(resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait'), inputs)

    expect(result.result).to eq('wait')
    expect(result.result_message)
      .to include('Relaunch DTR from the in-progress QuestionnaireResponse saved during the previous test.')
  end

  it 'describes each wait with its own step instead of completing the Questionnaire' do
    initial = resume_wait('dtr_full_ehr_v220_resume_initial_interaction_wait')
    relaunch = resume_wait('dtr_full_ehr_v220_resume_relaunch_interaction_wait')

    expect(initial.description).to include('answers some of its questions, and saves the in-progress')
    expect(relaunch.description).to include('relaunches DTR from the saved')
    [initial, relaunch].each do |wait_test|
      expect(wait_test.description).to_not include('completes the questionnaire')
    end
  end
end
