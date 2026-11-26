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

  describe 'config.options[:interaction_message]' do
    let(:custom_message_test_class) do
      Class.new(described_class) do
        id :interaction_wait_custom_message_spec_test
        config options: {
          interaction_message: "Do these things:\n- **Change** a pre-populated answer\n\n" \
                               "[Continue](%<continuation_url>s) to attest.\n"
        }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(custom_message_test_class) unless tests_repo.exists?(custom_message_test_class.id.to_s)
    end

    it 'replaces everything before the endpoint details with the configured message' do
      result = run(custom_message_test_class, { client_id: })

      expect(result.result).to eq('wait')
      expect(result.result_message).to start_with("Do these things:\n- **Change** a pre-populated answer\n")
      expect(result.result_message).to_not include('Inferno will wait while the tester uses the DTR client')
      expect(result.result_message).to include("\n### Endpoints\n")
    end

    it 'fills in the link to continue' do
      result = run(custom_message_test_class, { client_id: })

      expect(result.result_message).to match(%r{\[Continue\]\(\S+/resume_pass\?token=#{client_id}\) to attest\.})
    end

    it 'uses the standard message, with its link to continue, when no message is configured' do
      result = run(always_run_test_class, { client_id: })

      expect(result.result_message).to start_with('Inferno will wait while the tester uses the DTR client')
      expect(result.result_message).to match(%r{\[Click here\]\(\S+/resume_pass\?token=#{client_id}\)})
      expect(result.result_message).to include("\n### Endpoints\n")
    end

    it 'closes the code span around the FHIR Base URL in the standard message' do
      result = run(always_run_test_class, { client_id: })

      expect(result.result_message).to match(%r{^- FHIR Base: `\S+/fhir`$})
    end

    it 'indents no line by four or more spaces, so no part renders as a code block' do
      [custom_message_test_class, always_run_test_class].each do |test_class|
        result = run(test_class, { client_id: })

        expect(result.result_message.lines.grep(/\A {4,}\S/)).to be_empty
      end
    end
  end

  describe 'config.options[:interaction_attestation]' do
    let(:attestation_test_class) do
      Class.new(described_class) do
        id :interaction_wait_attestation_message_spec_test
        config options: { interaction_attestation: { instructions: "Do these things:\n- Stop the user\n",
                                                     statement: 'the client stopped the user.' } }
      end
    end

    let(:both_messages_test_class) do
      Class.new(described_class) do
        id :interaction_wait_both_messages_spec_test
        config options: { interaction_message: 'Continue [here](%<continuation_url>s).',
                          interaction_attestation: { instructions: 'Do it.', statement: 'it was done.' } }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      [attestation_test_class, both_messages_test_class].each do |runnable|
        tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)
      end
    end

    it 'lays out the instructions, statement and true / false links in the standard attestation format' do
      result = run(attestation_test_class, { client_id: })

      expect(result.result).to eq('wait')
      expect(result.result_message).to start_with(
        "Do these things:\n- Stop the user\n\nOnce the above steps have been completed, respond to the following " \
        "statement\nto continue to Inferno's evaluation of the interaction:\n\n" \
        "I attest that the client stopped the user.\n\n"
      )
      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_pass\?token=#{client_id}\) if the above statement is \*\*true\*\*\.})
      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_fail\?token=#{client_id}\) if the above statement is \*\*false\*\*\.})
      expect(result.result_message).to include("\n### Endpoints\n")
      expect(result.result_message.lines.grep(/\A {4,}\S/)).to be_empty
    end

    def session_outputs
      session_data_repo.get_all_from_session(test_session.id).to_h { |data| [data.name, data.value] }
    end

    it 'outputs only the true and false links shown in the dialog' do
      run(attestation_test_class, { client_id: })

      expect(session_outputs['attest_true_url']).to end_with("/resume_pass?token=#{client_id}")
      expect(session_outputs['attest_false_url']).to end_with("/resume_fail?token=#{client_id}")
      expect(session_outputs).to_not have_key('continuation_url')
    end

    it 'outputs only the continuation link for the continuation pattern' do
      run(always_run_test_class, { client_id: })

      expect(session_outputs['continuation_url']).to end_with("/resume_pass?token=#{client_id}")
      expect(session_outputs).to_not include('attest_true_url', 'attest_false_url')
    end

    it 'errors when a group sets both message options' do
      result = run(both_messages_test_class, { client_id: })

      expect(result.result).to eq('error')
      expect(result.result_message).to include('not both')
    end
  end
end
