# frozen_string_literal: true

require(
  'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/' \
  'adaptive_questionnaire_response_contained_questionnaire_test'
)

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe(
  DaVinciDTRTestKit::DTRPayerServerV220::AdaptiveQuestionnaireResponseContainedQuestionnaireTest,
  :runnable
) do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:canonical) { 'https://example.org/fhir/Questionnaire/adaptive|1.0.0' }

  def store_response(response_body)
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(
      :request,
      result_id: result.id,
      test_session_id: test_session.id,
      response_body:,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
  end

  def adaptive_questionnaire
    FHIR::Questionnaire.new(
      url: canonical.split('|').first,
      version: canonical.split('|').last,
      status: 'active',
      extension: [
        FHIR::Extension.new(
          url: described_class::ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL,
          valueBoolean: true
        )
      ]
    )
  end

  def questionnaire_response(reference: '#contained-questionnaire', derived_from: [canonical])
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      questionnaire: reference,
      contained: [
        FHIR::Questionnaire.new(
          id: 'contained-questionnaire',
          status: 'active',
          derivedFrom: derived_from
        )
      ]
    )
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

  it 'passes when the QuestionnaireResponse references a contained Questionnaire derived from the adaptive canonical' do
    store_response(questionnaire_package_response(adaptive_questionnaire, questionnaire_response))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when an adaptive Questionnaire package contains no QuestionnaireResponse' do
    store_response(questionnaire_package_response(adaptive_questionnaire))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Adaptive QuestionnaireResponses must reference a contained Questionnaire')
  end

  it 'fails when QuestionnaireResponse.questionnaire does not reference a contained resource' do
    store_response(
      questionnaire_package_response(adaptive_questionnaire, questionnaire_response(reference: canonical))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Adaptive QuestionnaireResponses must reference a contained Questionnaire')
  end

  it 'fails when the referenced contained Questionnaire does not exist' do
    store_response(
      questionnaire_package_response(adaptive_questionnaire, questionnaire_response(reference: '#missing'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Adaptive QuestionnaireResponses must reference a contained Questionnaire')
  end

  it 'fails when the contained Questionnaire is not derived from the adaptive canonical' do
    store_response(
      questionnaire_package_response(
        adaptive_questionnaire,
        questionnaire_response(derived_from: ['https://example.org/fhir/Questionnaire/other'])
      )
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Adaptive QuestionnaireResponses must reference a contained Questionnaire')
  end

  it 'omits when no adaptive Questionnaire package was returned' do
    store_response(questionnaire_package_response(FHIR::Questionnaire.new(status: 'active')))

    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('No adaptive Questionnaire packages were returned')
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
