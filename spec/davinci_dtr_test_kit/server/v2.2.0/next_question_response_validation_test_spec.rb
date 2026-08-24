# frozen_string_literal: true

require 'spec_helper'
require 'davinci_dtr_test_kit/server/v2.2.0/next_question_support/next_question_response_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::NextQuestionResponseValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  it 'omits if no requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('No $next-question')
  end

  it 'fails if no successful requests have been made' do
    request = repo_create(:request, status: 400, response_body: '{}')

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('was unsuccessful')
  end

  it 'fails if a response contains invalid JSON' do
    request = repo_create(:request)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('invalid JSON')
  end

  it 'fails if a response does not contain a FHIR resource' do
    request = repo_create(:request, response_body: '{}')

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('did not contain FHIR resources')
  end

  it 'fails if a response is neither Parameters nor QuestionnaireResponse' do
    request = repo_create(:request, response_body: FHIR::Patient.new.to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('not a Parameters or QuestionnaireResponse')
  end

  it 'fails if profile validation fails' do
    response = FHIR::QuestionnaireResponse.new(status: 'in-progress')
    request = repo_create(:request, response_body: response.to_json)
    error_message = { type: 'error', message: 'validation error' }

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(false)
    allow_any_instance_of(described_class).to receive(:messages).and_return([error_message])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('validation error')
  end

  it 'passes if a valid Parameters response is returned' do
    request = repo_create(:request, response_body: FHIR::Parameters.new.to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)

    result = run(described_class)

    expect(result.result).to eq('pass')
  end

  it 'passes if a valid QuestionnaireResponse response is returned' do
    response = FHIR::QuestionnaireResponse.new(status: 'in-progress')
    request = repo_create(:request, response_body: response.to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)

    result = run(described_class)

    expect(result.result).to eq('pass')
  end
end
