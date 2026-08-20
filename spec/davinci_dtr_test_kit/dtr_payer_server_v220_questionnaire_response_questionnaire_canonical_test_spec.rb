# frozen_string_literal: true

require(
  'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/questionnaire_response_questionnaire_canonical_test'
)

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireResponseQuestionnaireCanonicalTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def store_response(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, test_session_id: test_session.id, response_body:, tags:)
  end

  def questionnaire_package_response(*resources)
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: resources.map { |resource| FHIR::Bundle::Entry.new(resource:) }
          )
        )
      ]
    ).to_json
  end

  it 'passes when QuestionnaireResponse.questionnaire matches the package Questionnaire canonical' do
    questionnaire = FHIR::Questionnaire.new(
      status: 'active', url: 'https://payer.example.com/Questionnaire/example', version: '1.0.0'
    )
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress', questionnaire: 'https://payer.example.com/Questionnaire/example|1.0.0'
    )
    store_response(questionnaire_package_response(questionnaire, questionnaire_response))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when QuestionnaireResponse.questionnaire does not match the package Questionnaire canonical' do
    questionnaire = FHIR::Questionnaire.new(status: 'active', url: 'https://payer.example.com/Questionnaire/example')
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress', questionnaire: 'https://payer.example.com/Questionnaire/different'
    )
    store_response(questionnaire_package_response(questionnaire, questionnaire_response))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/must match a Questionnaire canonical in its package Bundle./)
    expect(result_messages.map(&:message).join).to include(
      '(Request 1) QuestionnaireResponse.questionnaire ' \
      '`https://payer.example.com/Questionnaire/different` does not match a Questionnaire canonical ' \
      'in its package Bundle (https://payer.example.com/Questionnaire/example).'
    )
  end

  it 'fails when QuestionnaireResponse.questionnaire is absent' do
    questionnaire = FHIR::Questionnaire.new(status: 'active', url: 'https://payer.example.com/Questionnaire/example')
    questionnaire_response = FHIR::QuestionnaireResponse.new(status: 'in-progress')
    store_response(questionnaire_package_response(questionnaire, questionnaire_response))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/must match a Questionnaire canonical in its package Bundle./)
  end

  it 'skips when no QuestionnaireResponse was returned' do
    store_response(questionnaire_package_response(FHIR::Questionnaire.new(status: 'active')))

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No QuestionnaireResponse resources were returned/)
  end
end
