RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireReferencesVersionTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:questionnaire_url) { 'https://payer.example/Questionnaire/prior-auth' }
  let(:library_url) { 'https://payer.example/Library/auth-rules' }
  let(:value_set_url) { 'https://payer.example/ValueSet/diagnoses' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def create_questionnaire_package_request(resource, status: 200)
    bundle = FHIR::Bundle.new(type: 'collection', entry: [{ resource: }])
    response = FHIR::Parameters.new(parameter: [{ name: 'packagebundle', resource: bundle }])

    repo_create(
      :request,
      result_id: result.id,
      name: 'questionnaire_package',
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status:,
      response_body: response.to_json
    )
  end

  def questionnaire(questionnaire_reference:, library_reference:, value_set_reference:)
    FHIR::Questionnaire.new(
      url: questionnaire_url,
      status: 'active',
      extension: [
        reference_extension('Questionnaire', questionnaire_reference),
        reference_extension('Library', library_reference),
        reference_extension('ValueSet', value_set_reference)
      ]
    )
  end

  def reference_extension(resource_type, reference)
    FHIR::Extension.new(
      url: "http://example.org/StructureDefinition/#{resource_type.downcase}-reference",
      valueReference: reference
    )
  end

  it 'passes when Questionnaire, Library, and ValueSet references all have versions' do
    create_questionnaire_package_request(
      questionnaire(
        questionnaire_reference: FHIR::Reference.new(type: 'Questionnaire', reference: "#{questionnaire_url}|1.0"),
        library_reference: FHIR::Reference.new(type: 'Library', reference: "#{library_url}|2.0"),
        value_set_reference: FHIR::Reference.new(type: 'ValueSet', reference: "#{value_set_url}|3.0")
      )
    )

    result = run(described_class)

    expect(result.result).to eq('pass')
  end

  it 'skips when no $questionnaire-package requests were made' do
    test_result = run(described_class)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No $questionnaire-package requests were made')
  end

  it 'skips when no successful $questionnaire-package requests were made' do
    create_questionnaire_package_request(FHIR::OperationOutcome.new, status: 500)

    test_result = run(described_class)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No successful $questionnaire-package requests were made')
  end

  it 'fails when a Questionnaire reference has no version' do
    questionnaire_reference = FHIR::Reference.new(type: 'Questionnaire', reference: questionnaire_url)

    create_questionnaire_package_request(
      questionnaire(
        questionnaire_reference:,
        library_reference: FHIR::Reference.new(type: 'Library', reference: "#{library_url}|2.0"),
        value_set_reference: FHIR::Reference.new(type: 'ValueSet', reference: "#{value_set_url}|3.0")
      )
    )

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end

  it 'fails when a Library reference has no version' do
    library_reference = FHIR::Reference.new(type: 'Library', reference: library_url)

    create_questionnaire_package_request(
      questionnaire(
        questionnaire_reference: FHIR::Reference.new(type: 'Questionnaire', reference: "#{questionnaire_url}|1.0"),
        library_reference:,
        value_set_reference: FHIR::Reference.new(type: 'ValueSet', reference: "#{value_set_url}|3.0")
      )
    )

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end

  it 'fails when a ValueSet reference has no version' do
    value_set_reference = FHIR::Reference.new(type: 'ValueSet', reference: value_set_url)

    create_questionnaire_package_request(
      questionnaire(
        questionnaire_reference: FHIR::Reference.new(type: 'Questionnaire', reference: "#{questionnaire_url}|1.0"),
        library_reference: FHIR::Reference.new(type: 'Library', reference: "#{library_url}|2.0"),
        value_set_reference:
      )
    )

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end
end
