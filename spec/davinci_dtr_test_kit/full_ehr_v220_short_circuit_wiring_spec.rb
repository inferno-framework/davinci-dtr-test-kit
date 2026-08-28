require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_request_validation_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_questionnaire_package_request_validation_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/response/dtr_next_question_response_validation_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/response/dtr_questionnaire_package_response_validation_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/ui_display_and_interaction_attestation_test'

# The interaction_wait_test sets scratch[:short_circuit] (via ShortCircuitInteractionVerification)
# to let Inferno know whether the tester declined the interaction or template setup failed, and
# each of the following tests calls check_for_short_circuit as the first line of its run block so
# it can pass/skip immediately instead of reporting a generic "no request was made" result. These
# examples verify that wiring in isolation, without needing to run the interaction test itself.
RSpec.shared_examples 'a short-circuit aware DTR full EHR v2.2.0 test' do |unaffected_skip_message|
  let(:suite_id) { 'dtr_full_ehr_v220' }

  it 'passes immediately with the default ok message when flagged to pass' do
    result = run(described_class, {}, { short_circuit: :pass })
    expect(result.result).to eq('pass')
    expect(result.result_message)
      .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::DEFAULT_SHORT_CIRCUIT_OK_MESSAGE)
  end

  it 'passes with the configured short_circuit_pass_message when one is set' do
    base_id = described_class.id
    configured_class = Class.new(described_class) do
      id :"#{base_id}_pass_message_spec_test"
      config options: { short_circuit_pass_message: 'Tester chose not to complete additional Questionnaires.' }
    end
    Inferno::Repositories::Tests.new.insert(configured_class)

    result = run(configured_class, {}, { short_circuit: :pass })
    expect(result.result).to eq('pass')
    expect(result.result_message).to eq('Tester chose not to complete additional Questionnaires.')
  end

  it 'skips immediately with the default setup-failure message when flagged to skip' do
    result = run(described_class, {}, { short_circuit: :skip })
    expect(result.result).to eq('skip')
    expect(result.result_message)
      .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::DEFAULT_SHORT_CIRCUIT_BAD_MESSAGE)
  end

  it 'runs its normal validation, unaffected, when no short circuit flag is present' do
    result = run(described_class, {}, {})
    expect(result.result).to eq('skip')
    expect(result.result_message).to eq(unaffected_skip_message)
  end
end

RSpec.describe 'DTR Full EHR v2.2.0 short-circuit wiring' do # rubocop:disable RSpec/DescribeClass
  describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnairePackageRequestValidationTest do
    it_behaves_like 'a short-circuit aware DTR full EHR v2.2.0 test',
                    'A Questionnaire Package request must be made prior to running this test'
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnairePackageResponseValidationTest do
    it_behaves_like 'a short-circuit aware DTR full EHR v2.2.0 test',
                    'A Questionnaire Package request must be made prior to running this test'
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionRequestValidationTest do
    it_behaves_like 'a short-circuit aware DTR full EHR v2.2.0 test',
                    'A $next-question request must be made prior to running this test'
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionResponseValidationTest do
    it_behaves_like 'a short-circuit aware DTR full EHR v2.2.0 test',
                    'A Next Question request must be made prior to running this test'
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220UIDisplayAndInteractionAttestationTest do
    it_behaves_like 'a short-circuit aware DTR full EHR v2.2.0 test',
                    'No Questionnaire Package requests returned a Questionnaire.'
  end
end
