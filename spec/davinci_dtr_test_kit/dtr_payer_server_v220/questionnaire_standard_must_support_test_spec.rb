require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_standard_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireStandardMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no standard Questionnaire was returned' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(adaptive_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No standard Questionnaires/)
  end

  it 'passes when the standard differential elements were demonstrated' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(standard_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end
end
