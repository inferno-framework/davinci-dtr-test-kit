require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:client_id) { 'short_circuit_spec_client_id' }

  let(:valid_qp_template) do
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: FHIR::Bundle.new(type: 'collection'))
      ]
    ).to_json
  end
  let(:valid_nq_template) { '[]' }

  # Wired the way DTRFullEHRV220AdditionalQuestionnairesForMS wires the real interaction wait
  # test: a radio input controlling whether the tester is completing Questionnaires this run,
  # plus the two response template inputs.
  let(:test_class) do
    Class.new(described_class) do
      id :short_circuit_interaction_wait_spec_test
      input :complete_questionnaires, type: 'radio', optional: false
      input :qp_template, type: 'textarea', optional: true
      input :nq_template, type: 'textarea', optional: true
      config options: {
        short_circuit_pass_input: 'complete_questionnaires',
        short_circuit_pass_message: 'Tester declined to complete Questionnaires.',
        qp_response_template_input: 'qp_template',
        nq_questionnaire_template_input: 'nq_template'
      }
    end
  end

  # No short_circuit_pass_input configured, matching how the workflow-adaptive group uses
  # this test (no option to decline the interaction).
  let(:always_run_test_class) do
    Class.new(described_class) do
      id :short_circuit_interaction_wait_no_config_spec_test
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    [test_class, always_run_test_class].each do |runnable|
      tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)
    end

    # The wait message interpolates FHIR base/operation URLs, which need a suite_id to build;
    # these spec subclasses aren't mounted in a real suite tree, so stub it directly.
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
  end

  describe 'when the tester declines to complete Questionnaires' do
    it 'passes immediately with the configured message and flags downstream tests to pass' do
      scratch = {}
      result = run(test_class, { client_id:, complete_questionnaires: 'false' }, scratch)

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('Tester declined to complete Questionnaires.')
      expect(scratch[:short_circuit]).to eq(:pass)
    end

    it 'does not validate the (unused) response templates' do
      scratch = {}
      result = run(test_class, {
                     client_id:, complete_questionnaires: 'false', qp_template: 'not json', nq_template: 'not json'
                   }, scratch)

      expect(result.result).to eq('pass')
      expect(scratch[:short_circuit]).to eq(:pass)
    end
  end

  describe 'when the tester chooses to complete Questionnaires' do
    it 'waits for the interaction when the templates are valid' do
      scratch = {}
      result = run(test_class, {
                     client_id:, complete_questionnaires: 'true', qp_template: valid_qp_template,
                     nq_template: valid_nq_template
                   }, scratch)

      expect(result.result).to eq('wait')
      expect(scratch).to_not have_key(:short_circuit)
    end

    it 'fails and flags downstream tests to skip when the $questionnaire-package template is invalid' do
      scratch = {}
      result = run(test_class, {
                     client_id:, complete_questionnaires: 'true', qp_template: 'not json',
                     nq_template: valid_nq_template
                   }, scratch)

      expect(result.result).to eq('fail')
      expect(scratch[:short_circuit]).to eq(:skip)
    end

    it 'fails and flags downstream tests to skip when the $next-question template is invalid' do
      scratch = {}
      result = run(test_class, {
                     client_id:, complete_questionnaires: 'true', qp_template: valid_qp_template,
                     nq_template: 'not json'
                   }, scratch)

      expect(result.result).to eq('fail')
      expect(scratch[:short_circuit]).to eq(:skip)
    end

    it 'fails and flags downstream tests to skip when a template is missing entirely' do
      scratch = {}
      result = run(test_class, { client_id:, complete_questionnaires: 'true' }, scratch)

      expect(result.result).to eq('fail')
      expect(scratch[:short_circuit]).to eq(:skip)
    end
  end

  describe 'when no short_circuit_pass_input is configured' do
    it 'always proceeds to wait for the interaction' do
      result = run(always_run_test_class, { client_id: })
      expect(result.result).to eq('wait')
    end
  end
end
