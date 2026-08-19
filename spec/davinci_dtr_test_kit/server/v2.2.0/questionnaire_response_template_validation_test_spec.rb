RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireResponseTemplateValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  it 'omits if no QuestionnaireResponse templates are provided' do
    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('No QuestionnaireResponse templates were provided')
  end

  it 'fails if the input is not valid JSON' do
    result = run(described_class, questionnaire_response_templates: 'not json')

    expect(result.result).to eq('fail')
  end

  it 'fails if an input is not a recognized FHIR resource' do
    result = run(described_class, questionnaire_response_templates: '{}')

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant QuestionnaireResponse template input')
    expect(result_messages.first.message).to include('[Resource 1] Resource does not contain a recognized FHIR object')
  end

  it 'fails if an input is not a QuestionnaireResponse resource' do
    template = FHIR::Patient.new.to_json

    result = run(described_class, questionnaire_response_templates: template)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant QuestionnaireResponse template input')
    expect(result_messages.first.message).to include(
      '[Resource 1] Unexpected resource type: expected QuestionnaireResponse'
    )
  end

  it 'fails if an input does not conform to the profile' do
    template = FHIR::QuestionnaireResponse.new.to_json

    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(false)

    result = run(described_class, questionnaire_response_templates: template)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant QuestionnaireResponse template input')
    expect(result_messages.first.message).to include('[Resource 1] Resource does not conform to the profile')
  end

  it 'passes when every provided QuestionnaireResponse resource conforms to the profile' do
    templates = [FHIR::QuestionnaireResponse.new.to_hash, FHIR::QuestionnaireResponse.new.to_hash].to_json

    expect_any_instance_of(described_class).to receive(:resource_is_valid?).twice.and_return(true)

    result = run(described_class, questionnaire_response_templates: templates)

    expect(result.result).to eq('pass')
  end
end
