require 'davinci_dtr_test_kit/server/v2.2.0/must_support/' \
        'questionnaire_package_output_parameters_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePackageOutputParametersMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no tagged server responses are available' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Requests must be made prior')
  end

  it 'passes when the outcome parameter is not demonstrated' do
    store_must_support_response(
      questionnaire_package_response(questionnaire_package_bundle(FHIR::Questionnaire.new(status: 'active')))
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when no packagebundle parameter was demonstrated' do
    store_must_support_response(
      FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(
          name: 'outcome',
          resource: FHIR::OperationOutcome.new(issue: [FHIR::OperationOutcome::Issue.new(severity: 'warning')])
        )]
      ).to_json
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Parameters.parameter:packagebundle')
  end

  it 'does not check for the outcome parameter' do
    expect(described_class::MUST_SUPPORT_METADATA.must_support_strings)
      .to contain_exactly('parameter', 'parameter:packagebundle', 'parameter:packagebundle.resource')
  end

  it 'does not modify the cached generated metadata' do
    cached_metadata = DaVinciDTRTestKit::GeneratedProfileMetadata.for('v2.2.0', 'dtr_qpackage_output_parameters')

    expect(cached_metadata.must_support_strings).to include('parameter:outcome', 'parameter:outcome.resource')
  end
end
