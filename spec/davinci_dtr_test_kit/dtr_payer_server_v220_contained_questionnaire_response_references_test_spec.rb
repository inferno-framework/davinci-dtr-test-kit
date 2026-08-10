# frozen_string_literal: true

require(
  'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/contained_questionnaire_response_references_test'
)

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ContainedQuestionnaireResponseReferencesTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }

  def store_response(response_body, tags: [DaVinciDTRTestKit::NEXT_TAG])
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, test_session_id: test_session.id, response_body:, tags:)
  end

  it 'passes when a contained reference is an answer value' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      contained: [FHIR::Observation.new(id: 'answer')],
      item: [FHIR::QuestionnaireResponse::Item.new(
        linkId: '1',
        answer: [
          FHIR::QuestionnaireResponse::Item::Answer.new(
            valueReference: FHIR::Reference.new(reference: '#answer')
          )
        ]
      )]
    )
    store_response(questionnaire_response.to_json)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when a contained reference is outside an answer value' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      contained: [FHIR::Patient.new(id: 'patient')],
      subject: FHIR::Reference.new(reference: '#patient')
    )
    store_response(questionnaire_response.to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/only in item.answer valueReference/)
  end

  it 'skips when no QuestionnaireResponse was returned' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No QuestionnaireResponse resources were returned/)
  end
end
