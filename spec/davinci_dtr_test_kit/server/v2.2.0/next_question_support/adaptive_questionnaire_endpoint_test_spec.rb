# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/next_question_support/adaptive_questionnaire_endpoint_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::AdaptiveQuestionnaireEndpointTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:payer_base_url) { 'https://payer.example/fhir' }
  let(:adaptive_url) { "#{payer_base_url}/adaptive" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def adaptive_questionnaire_package(url: adaptive_url)
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::Questionnaire.new(
                  status: 'draft',
                  extension: [FHIR::Extension.new(
                    url: described_class::ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL,
                    valueUrl: url
                  )]
                )
              )
            ]
          )
        )
      ]
    ).to_json
  end

  def request(response_body: '', url: "#{payer_base_url}/Questionnaire/$questionnaire-package", status: 200)
    repo_create(:request, response_body:, url:, status:)
  end

  def adaptive_questionnaire_request(url: adaptive_url)
    request(response_body: adaptive_questionnaire_package(url:))
  end

  def run_with_requests(questionnaire_requests:, next_question_requests: [])
    allow_any_instance_of(described_class).to receive(:load_tagged_requests) do |_test, tag|
      tag == DaVinciDTRTestKit::QUESTIONNAIRE_TAG ? questionnaire_requests : next_question_requests
    end

    run(described_class, url: payer_base_url)
  end

  it 'passes for a payer sub-URL with a successful next-question request' do
    result = run_with_requests(
      questionnaire_requests: [adaptive_questionnaire_request],
      next_question_requests: [request(url: "#{adaptive_url}/Questionnaire/$next-question")]
    )

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes when the adaptive Questionnaire URL is the payer base URL' do
    result = run_with_requests(
      questionnaire_requests: [adaptive_questionnaire_request(url: payer_base_url)],
      next_question_requests: [request(url: "#{payer_base_url}/Questionnaire/$next-question")]
    )

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when the adaptive Questionnaire URL is outside the payer base' do
    result = run_with_requests(
      questionnaire_requests: [adaptive_questionnaire_request(url: 'https://other-payer.example/fhir/adaptive')]
    )

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('is not a sub-URL of payer base')
  end

  it 'fails when no next-question request is made to the adaptive Questionnaire URL' do
    result = run_with_requests(questionnaire_requests: [adaptive_questionnaire_request])

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('No $next-question request was made')
  end

  it 'fails when the next-question request does not succeed' do
    result = run_with_requests(
      questionnaire_requests: [adaptive_questionnaire_request],
      next_question_requests: [request(url: "#{adaptive_url}/Questionnaire/$next-question", status: 401)]
    )

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('received HTTP 401')
  end

  it 'omits when no adaptive Questionnaire URL is returned' do
    result = run_with_requests(questionnaire_requests: [request(response_body: FHIR::Parameters.new.to_json)])

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('No adaptive Questionnaire URLs were returned')
  end
end
