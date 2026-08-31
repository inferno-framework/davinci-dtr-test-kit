require 'davinci_dtr_test_kit/server/v2.2.0/must_support/' \
        'questionnaire_package_output_parameters_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePackageOutputParametersMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no tagged server responses are available' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Requests must be made prior/)
  end

  it 'passes when must support parameters are present cumulatively across responses' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(FHIR::Questionnaire.new(status: 'active')))
    )
    store_must_support_response(
      FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(
          name: 'outcome',
          resource: FHIR::OperationOutcome.new(issue: [FHIR::OperationOutcome::Issue.new(severity: 'warning')])
        )]
      ).to_json
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when no outcome parameter was demonstrated' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(FHIR::Questionnaire.new(status: 'active')))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Parameters.parameter:outcome')
  end
end
