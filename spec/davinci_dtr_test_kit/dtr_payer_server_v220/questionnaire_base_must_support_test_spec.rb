require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_base_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireBaseMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when only an adaptive-search Questionnaire was returned' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(adaptive_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No standard or adaptive Questionnaires/)
  end

  it 'fails when the base Questionnaire must support elements have not all been demonstrated' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(standard_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('url')
  end

  it 'ignores adaptive-search Questionnaires' do
    captured_resources = capture_asserted_resources(described_class)
    store_must_support_response(
      questionnaire_package_response(
        questionnaire_package_bundle(standard_questionnaire),
        questionnaire_package_bundle(adaptive_questionnaire(id: 'adaptive-search'))
      )
    )
    store_must_support_response(
      next_question_response(adaptive_questionnaire(id: 'adaptive-next')),
      url: next_question_url,
      tag: DaVinciDTRTestKit::NEXT_TAG
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(captured_resources.map(&:id)).to contain_exactly('standard', 'adaptive-next')
  end
end
