# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/questionnaire_response_references_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireResponseReferencesTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }

  def store_response(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, test_session_id: test_session.id, response_body:, tags:)
  end

  def questionnaire_package_response(questionnaire_response)
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [FHIR::Bundle::Entry.new(resource: questionnaire_response)]
          )
        )
      ]
    ).to_json
  end

  it 'passes when questionnaire package responses use relative client references' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'Patient/example')
    )
    store_response(questionnaire_package_response(questionnaire_response))

    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when a questionnaire package response references another endpoint' do
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'https://payer.example/fhir/Patient/example')
    )
    store_response(questionnaire_package_response(questionnaire_response))

    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/DTR client's FHIR endpoint/)
  end

  it 'skips when no QuestionnaireResponse was returned' do
    result = run(described_class, client_fhir_endpoint: 'https://client.example/fhir')

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No QuestionnaireResponse resources were returned/)
  end
end
