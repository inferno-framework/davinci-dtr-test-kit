require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_adaptive_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireAdaptiveMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no adaptive Questionnaire was returned by $next-question' do
    store_must_support_response(
      FHIR::QuestionnaireResponse.new(status: 'in-progress').to_json,
      url: next_question_url,
      tag: DaVinciDTRTestKit::NEXT_TAG
    )

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No adaptive Questionnaires/)
  end

  it 'passes when the adaptive differential elements were demonstrated' do
    store_must_support_response(
      next_question_response(adaptive_questionnaire),
      url: next_question_url,
      tag: DaVinciDTRTestKit::NEXT_TAG
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end
end
