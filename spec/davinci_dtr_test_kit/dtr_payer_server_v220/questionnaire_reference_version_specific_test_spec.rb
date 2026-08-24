RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireReferencesVersionTest do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:questionnaire_url) { 'https://payer.example/Questionnaire/prior-auth' }
  let(:library_url) { 'https://payer.example/Library/auth-rules' }
  let(:value_set_url) { 'https://payer.example/ValueSet/diagnoses' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def build_bundle(questionnaire, resources = [])
    bundle_hash = { entry: [{ resource: questionnaire }] }

    resources.each do |resource|
      bundle_hash[:entry] << { resource: }
    end

    FHIR::Bundle.new(bundle_hash)
  end

  def response_params(bundle)
    FHIR::Parameters.new(parameter: [{ name: 'packagebundle', resource: bundle }])
  end

  def create_questionnaire_package_request(response_resource, status: 200)
    repo_create(
      :request,
      result_id: result.id,
      name: 'questionnaire_package',
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status:,
      response_body: response_resource.to_json
    )
  end

  def questionnaire(questionnaire_version: '1.0', library_canonical: nil, value_set_canonical: nil)
    extensions = []
    if library_canonical.present?
      extensions << {
        url: 'http://hl7.org/fhir/StructureDefinition/cqf-library',
        valueCanonical: library_canonical
      }
    end

    items = []
    if value_set_canonical.present?
      items << FHIR::Questionnaire::Item.new(
        answerValueSet: value_set_canonical
      )
    end

    FHIR::Questionnaire.new(
      url: questionnaire_url,
      version: questionnaire_version,
      status: 'active',
      extension: extensions,
      item: items
    )
  end

  it 'passes when Questionnaire, Library, and ValueSet references all have versions' do
    create_questionnaire_package_request(
      response_params(
        build_bundle(
          questionnaire(
            library_canonical: "#{library_url}|2.0",
            value_set_canonical: "#{value_set_url}|3.0"
          )
        )
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

  it 'fails when the bundled Questionnaire has no version' do
    create_questionnaire_package_request(
      response_params(build_bundle(questionnaire(questionnaire_version: nil)))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end

  it 'fails when a Library reference has no version' do
    create_questionnaire_package_request(
      response_params(build_bundle(questionnaire(library_canonical: library_url)))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end

  it 'fails when a ValueSet reference has no version' do
    create_questionnaire_package_request(
      response_params(build_bundle(questionnaire(value_set_canonical: value_set_url)))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'References to Questionnaires, Libraries, and ValueSets within questionnaire package Bundles must be ' \
      'version-specific. See Messages for details.'
    )
  end
end
