require 'davinci_dtr_test_kit/full_ehr/v2.2.0/workflows/dtr_full_ehr_workflow_answer_origin_group'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowAnswerOrigin do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }

  # 2.3 as it is mounted in the suite, and its copy of the interaction wait test, which carries the
  # group's config and inputs.
  let(:mounted_group) do
    suite = Inferno::Repositories::TestSuites.new.find(suite_id)
    workflows_group = suite.groups.find { |group| group.id.to_s.end_with?('questionnaire_workflows') }
    workflows_group.groups.find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_workflow_answer_origin') }
  end
  let(:wait_test) do
    interaction_group = mounted_group.groups.first
    interaction_group.tests.find { |test| test.id.to_s.end_with?('dtr_full_ehr_v220_interaction_wait') }
  end

  let(:fixture_directory) { File.join('lib', 'davinci_dtr_test_kit', 'full_ehr', 'fixtures', 'dinner_adaptive') }
  let(:default_inputs) do
    {
      client_id: 'answer_origin_group_spec_client_id',
      answer_origin_qp_template:
        File.read(File.join(fixture_directory, 'parameters_questionnaire_dinner_order_adaptive.json')),
      answer_origin_nq_template:
        File.read(File.join(fixture_directory, 'dinner_order_adaptive_next_question_template.json'))
    }
  end

  it 'tells the simulated payer where to find tester-provided Libraries and ValueSets' do
    expect(wait_test.config.options[:library_bundle_input]).to eq('answer_origin_libraries')
    expect(wait_test.config.options[:value_set_bundle_input]).to eq('answer_origin_value_sets')
  end

  it 'makes the Library and ValueSet inputs optional' do
    expect(mounted_group.config.input(:answer_origin_libraries).optional).to be(true)
    expect(mounted_group.config.input(:answer_origin_value_sets).optional).to be(true)
  end

  it 'starts the interaction when the Library and ValueSet inputs are left blank' do
    result = run(wait_test, default_inputs)

    expect(result.result).to eq('wait'), result.result_message
  end

  it 'fails before the interaction when the Library input is not a Bundle' do
    scratch = {}
    library_input = { resourceType: 'Library', status: 'active', type: { text: 'logic-library' } }.to_json

    result = run(wait_test, default_inputs.merge(answer_origin_libraries: library_input), scratch)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include("Input 'Answer Origin CQL Libraries' must contain a Bundle resource.")
    expect(scratch[:short_circuit]).to eq(:skip)
  end

  it 'fails before the interaction when the ValueSet input is not a Bundle' do
    value_set_input = { resourceType: 'ValueSet', status: 'active' }.to_json

    result = run(wait_test, default_inputs.merge(answer_origin_value_sets: value_set_input))

    expect(result.result).to eq('fail')
    expect(result.result_message).to include("Input 'Answer Origin ValueSets' must contain a Bundle resource.")
  end
end
