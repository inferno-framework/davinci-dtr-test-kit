require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_adaptive_search_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireAdaptiveSearchMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no $questionnaire-package requests were made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No Questionnaires were found')
  end

  it 'skips when $questionnaire-package responses contain no Questionnaires' do
    store_must_support_response(FHIR::Parameters.new.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No Questionnaires were found')
  end

  it 'omits when only standard Questionnaires were returned' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(standard_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('did not return any adaptive-search Questionnaires')
  end

  it 'fails when the adaptive-search Questionnaire must support elements have not all been demonstrated' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(adaptive_questionnaire))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('url')
  end

  it 'ignores standard and $next-question Questionnaires' do
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
    expect(captured_resources.map(&:id)).to eq(['adaptive-search'])
  end
end
