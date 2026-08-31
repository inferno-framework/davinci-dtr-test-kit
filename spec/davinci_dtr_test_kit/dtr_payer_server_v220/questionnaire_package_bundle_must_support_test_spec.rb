require 'davinci_dtr_test_kit/server/v2.2.0/must_support/questionnaire_package_bundle_must_support_test'
require_relative 'server_must_support_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePackageBundleMustSupportTest do
  include ServerMustSupportSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }

  it 'skips when no package Bundles are available' do
    store_must_support_response(FHIR::Parameters.new.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Questionnaire Package Bundle/)
  end

  it 'passes when must support entries are present cumulatively across package Bundles' do
    first_bundle = questionnaire_package_bundle(
      FHIR::Questionnaire.new(status: 'active'),
      FHIR::QuestionnaireResponse.new(status: 'in-progress')
    )
    second_bundle = questionnaire_package_bundle(
      FHIR::Questionnaire.new(status: 'active'),
      FHIR::QuestionnaireResponse.new(status: 'in-progress'),
      FHIR::ValueSet.new(status: 'active'),
      FHIR::Library.new(status: 'active')
    )
    store_must_support_response(questionnaire_package_response(first_bundle, second_bundle))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when no Library entry was demonstrated' do
    bundle = questionnaire_package_bundle(
      FHIR::Questionnaire.new(status: 'active'),
      FHIR::QuestionnaireResponse.new(status: 'in-progress'),
      FHIR::ValueSet.new(status: 'active')
    )
    store_must_support_response(questionnaire_package_response(bundle))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Bundle.entry:library')
  end
end
