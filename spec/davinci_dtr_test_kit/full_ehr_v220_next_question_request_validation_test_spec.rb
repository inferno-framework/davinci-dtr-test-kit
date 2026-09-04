require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_request_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:next_question_url) { described_class.new.next_url }

  # Results returned directly by `run` never carry their `messages` (a repository quirk:
  # Results::create strips :messages from the params before building the in-memory entity,
  # even though it persists them), so reload from the session to see per-message detail.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def create_nq_request(request_body, url: next_question_url)
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      request_body:,
      tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG],
      status: 200
    )
  end

  def bare_qr_json(status: 'in-progress')
    { resourceType: 'QuestionnaireResponse', status: }.to_json
  end

  def wrapped_input_params_json(status: 'in-progress')
    {
      resourceType: 'Parameters',
      parameter: [{ name: 'questionnaire-response', resource: { resourceType: 'QuestionnaireResponse', status: } }]
    }.to_json
  end

  def stub_valid_resource
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)
  end

  it 'skips when no $next-question requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A $next-question request must be made')
  end

  it 'fails and reports the wrong URL when the request was not made to the $next-question endpoint' do
    stub_valid_resource
    create_nq_request(bare_qr_json, url: '/some/other/url')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/Request made to wrong URL/))
  end

  it 'fails when the request body is not valid JSON' do
    create_nq_request('not json')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/does not contain a recognized FHIR resource/))
  end

  it 'validates a bare QuestionnaireResponse request body against the adaptive response profile' do
    create_nq_request(bare_qr_json)
    validated_with = nil
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |_instance, **kwargs|
      validated_with = kwargs
      true
    end

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(validated_with).to include(
      resource: an_instance_of(FHIR::QuestionnaireResponse),
      profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0'
    )
  end

  it 'validates a Parameters request body against the next-question input parameters profile' do
    create_nq_request(wrapped_input_params_json)
    validated_with = nil
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |_instance, **kwargs|
      validated_with = kwargs
      true
    end

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(validated_with).to include(
      resource: an_instance_of(FHIR::Parameters),
      profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-input-parameters|2.2.0'
    )
  end

  it 'fails and reports the unexpected resource type when the body is neither shape' do
    create_nq_request({ resourceType: 'OperationOutcome', issue: [] }.to_json)

    expect_any_instance_of(described_class).to_not receive(:resource_is_valid?)

    result = run(described_class)

    expect(result.result).to eq('fail')
    message = messages_for(result).find { |candidate| candidate.include?('unexpected resource type') }
    expect(message).to include('expected Parameters or QuestionnaireResponse')
    expect(message).to include('OperationOutcome')
  end

  it 'fails when the validator rejects the resource' do
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |test_instance|
      test_instance.add_message('error', 'Resource is not conformant to the profile.')
      false
    end
    create_nq_request(bare_qr_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  describe 'short-circuiting via scratch[:short_circuit]' do
    it 'passes immediately with the default message when flagged to pass' do
      result = run(described_class, {}, { short_circuit: :pass })

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('No Questionnaires need to be completed.')
    end

    it 'skips immediately with the default message when flagged to skip' do
      result = run(described_class, {}, { short_circuit: :skip })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Failed to setup the Inferno DTR payer server simulation.')
    end

    it 'fails immediately with the default message when flagged to fail' do
      result = run(described_class, {}, { short_circuit: :fail })

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Failed to setup the Inferno DTR payer server simulation.')
    end
  end
end
