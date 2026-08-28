require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_adaptive_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireAdaptiveMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no Questionnaire evidence was returned' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No adaptive Questionnaires/)
  end

  it 'skips when $questionnaire-package responses contain no Questionnaires' do
    store_must_support_response(FHIR::Parameters.new.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No adaptive Questionnaires/)
  end

  it 'omits when only standard Questionnaires were returned' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(standard_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to match(/did not return any adaptive-search Questionnaires/)
  end

  it 'skips when an adaptive-search Questionnaire was returned but no $next-question requests were made' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(adaptive_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No adaptive Questionnaires/)
  end

  it 'skips when $next-question responses contain no adaptive Questionnaires' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(adaptive_questionnaire))
    )
    store_must_support_response(
      FHIR::QuestionnaireResponse.new(status: 'in-progress').to_json,
      url: next_question_url,
      tag: DaVinciDTRTestKit::NEXT_TAG
    )

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No adaptive Questionnaires/)
  end

  it 'passes when $next-question demonstrates the adaptive differential without a $questionnaire-package request' do
    store_must_support_response(
      next_question_response(adaptive_questionnaire),
      url: next_question_url,
      tag: DaVinciDTRTestKit::NEXT_TAG
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end
end
