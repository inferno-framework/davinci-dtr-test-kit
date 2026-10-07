RSpec.describe DaVinciDTRTestKit::DTRPayerServerAdaptiveQuestionnairePackageGroup, :request do
  let(:suite_id) { 'dtr_payer_server' }
  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_payer_server-payer_server_adaptive_questionnaire') }
  let(:response_validation_test) { find_test('payer_server_adaptive_response_validation_test') }
  let(:expressions_test) { find_test('dtr_v201_payer_adaptive_form_expressions_test') }
  let(:bundles_validation_test) { find_test('payer_server_adaptive_response_bundles_validation_test') }
  let(:search_validation_test) { find_test('payer_server_adaptive_response_search_validation_test') }
  let(:inputs) { { retrieval_method: 'Adaptive', url: 'http://example.com/fhir' } }

  def find_test(id_suffix)
    group.tests.find { |test| test.id.to_s.end_with? id_suffix }
  end

  def conformant_adaptive_bundle
    FHIR::Bundle.new(
      type: 'collection',
      entry: [
        FHIR::Bundle::Entry.new(
          resource: FHIR::Questionnaire.new(
            url: 'urn:example:adaptive-q',
            status: 'draft',
            item: [
              FHIR::Questionnaire::Item.new(
                linkId: 'q1',
                type: 'string',
                extension: [
                  FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
                    valueExpression: FHIR::Expression.new(language: 'text/cql', expression: '"InitExpr"')
                  ),
                  FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression',
                    valueExpression: FHIR::Expression.new(language: 'text/cql', expression: '"CandidateExpr"')
                  ),
                  FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression',
                    valueExpression: FHIR::Expression.new(language: 'text/cql', expression: '"ContextExpr"')
                  )
                ]
              )
            ]
          )
        )
      ]
    ).to_json
  end

  def record_questionnaire_package_request
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(
      :request,
      result_id: result.id,
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status: 200,
      response_body: conformant_adaptive_bundle
    )
  end

  # Regression test for a bug where dtr_v201_payer_adaptive_form_expressions_test cleared
  # scratch[:adaptive_questionnaire_bundles] after using it, even though
  # payer_server_adaptive_response_bundles_validation_test and
  # payer_server_adaptive_response_search_validation_test run later in the same group and
  # still depend on that scratch value being present.
  it 'keeps the adaptive questionnaire bundle in scratch available to tests that run after the expressions test' do
    record_questionnaire_package_request

    allow_any_instance_of(response_validation_test).to receive(:assert_valid_resource).and_return(true)
    allow_any_instance_of(bundles_validation_test).to receive(:assert_valid_resource).and_return(true)
    allow_any_instance_of(search_validation_test).to receive(:assert_valid_resource).and_return(true)

    # A single shared scratch hash, passed to each `run` call below, reproduces how
    # Inferno::TestRunner#run_group threads one scratch hash through every test in a group run.
    scratch = {}

    validation_result = run(response_validation_test, inputs, scratch)
    expect(validation_result.result).to eq('pass'), validation_result.result_message

    expressions_result = run(expressions_test, inputs, scratch)
    expect(expressions_result.result).to eq('pass'), expressions_result.result_message

    bundles_result = run(bundles_validation_test, inputs, scratch)
    expect(bundles_result.result).to eq('pass'), bundles_result.result_message

    search_result = run(search_validation_test, inputs, scratch)
    expect(search_result.result).to eq('pass'), search_result.result_message
  end
end
