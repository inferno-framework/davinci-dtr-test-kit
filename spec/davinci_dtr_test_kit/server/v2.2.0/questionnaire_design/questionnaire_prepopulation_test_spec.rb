# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/questionnaire_prepopulation_test'
require_relative 'questionnaire_design_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePrepopulationTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  include QuestionnaireDesignSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:test_run) { repo_create(:test_run, test_session:, runnable: described_class.reference_hash) }
  let(:result) { repo_create(:result, test_session:, test_run:, runnable: described_class.reference_hash) }
  let(:questionnaire_url) { "/custom/#{suite_id}/Questionnaire/$questionnaire-package" }

  it 'passes when at least one of several Questionnaires includes prepopulation logic' do
    bare_questionnaire = questionnaire(items: [questionnaire_item])
    initial_expression_url = described_class::POPULATION_EXPRESSION_URLS.first
    populated_item = questionnaire_item(
      extensions: [expression_extension(initial_expression_url)]
    )
    populated_questionnaire = questionnaire(items: [populated_item])
    store_response(questionnaire_package_response(bare_questionnaire, populated_questionnaire))

    expect(run(described_class).result).to eq('pass')
  end

  it 'fails when no Questionnaire includes prepopulation logic' do
    store_response(questionnaire_package_response(questionnaire(items: [questionnaire_item])))

    test_result = run(described_class)
    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include('population from the EHR')
  end
end