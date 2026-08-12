# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/next_question_support/next_question_response_references_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::NextQuestionResponseReferencesTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }

  def store_response(response_body, tags: [DaVinciDTRTestKit::NEXT_TAG])
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, test_session_id: test_session.id, response_body:, tags:)
  end

  it 'passes when next-question responses use relative client references' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'Patient/example')
    )
    store_response(questionnaire_response.to_json)

    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when a next-question response references another endpoint' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'https://payer.example/fhir/Patient/example')
    )
    store_response(questionnaire_response.to_json)

    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/DTR client's FHIR endpoint/)
  end

  it 'skips when an absolute reference is returned without a client FHIR endpoint' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'https://client.example/fhir/Patient/example')
    )
    store_response(questionnaire_response.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/no DTR Client FHIR Endpoint was provided/)
  end

  it 'skips when no QuestionnaireResponse was returned' do
    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No QuestionnaireResponse resources were returned/)
  end
end
