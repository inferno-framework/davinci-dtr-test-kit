RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::AdaptiveQuestionnaireResponseValidationTest, :request do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:canonical) { 'urn:example:adaptive-q' }
  let(:adaptive_questionnaire_search_profile) do
    described_class::ADAPTIVE_QUESTIONNAIRE_SEARCH_PROFILE
  end

  let(:test_class) do
    Class.new(described_class) do
      id :dtr_v220_adaptive_questionnaire_response_spec

      validator do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
      end
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
  end

  def static_qp_response
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [FHIR::Bundle::Entry.new(resource: FHIR::Questionnaire.new(url: canonical, status: 'draft'))]
          )
        )
      ]
    ).to_json
  end

  def adaptive_qp_response
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::Questionnaire.new(
                  url: canonical, status: 'draft',
                  extension: [FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                    valueBoolean: true
                  )]
                )
              )
            ]
          )
        )
      ]
    ).to_json
  end

  def record_qp_response(response_body, status: 200)
    repo_create(
      :request,
      result:,
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status:,
      response_body:
    )
  end

  it 'skips when no $questionnaire-package requests were made' do
    result = run(test_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No $questionnaire-package requests were made.')
  end

  it 'skips when no adaptive Questionnaires are returned' do
    record_qp_response(static_qp_response)

    result = run(test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No adaptive Questionnaires were found')
  end

  it 'validates an adaptive Questionnaire against the search profile' do
    record_qp_response(adaptive_qp_response)

    stub_request(:post, validation_url)
      .with(query: { profile: adaptive_questionnaire_search_profile })
      .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

    result = run(test_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when profile validation fails' do
    record_qp_response(adaptive_qp_response)

    stub_request(:post, validation_url)
      .with(query: { profile: adaptive_questionnaire_search_profile })
      .to_return(
        status: 200,
        body: FHIR::OperationOutcome.new(
          issue: { severity: 'error', code: 'invalid' }
        ).to_json
      )

    result = run(test_class)

    expect(result.result).to eq('fail')
  end
end
