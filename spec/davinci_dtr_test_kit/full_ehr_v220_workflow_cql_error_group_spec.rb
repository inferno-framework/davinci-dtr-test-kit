require 'davinci_dtr_test_kit/full_ehr/v2.2.0/workflows/dtr_full_ehr_workflow_cql_error_group'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'
require 'davinci_dtr_test_kit/full_ehr/fixture_loader'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowCQLError do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:options) { described_class.config.options }
  let(:package_fixture) { DaVinciDTRTestKit::FixtureLoader.instance[options[:qp_response_template_fixture]] }
  let(:template_fixture) { DaVinciDTRTestKit::FixtureLoader.instance[options[:nq_questionnaire_template_fixture]] }
  let(:package_questionnaire) do
    package_fixture.parameter.find { |param| param.name == 'packagebundle' }.resource.entry.map(&:resource)
      .find { |resource| resource.is_a?(FHIR::Questionnaire) }
  end
  let(:canonical) { 'urn:inferno:dtr-test-kit:dinner-order-cql-error' }
  let(:adaptive_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive' }
  let(:calculated_expression_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression' }
  let(:initial_expression_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression' }
  let(:inclusion_criteria_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUSION_CRITERIA_URL }

  def all_items(items)
    items.flat_map { |item| [item] + all_items(item.item) }
  end

  def all_tests(runnable)
    runnable.tests + runnable.groups.flat_map { |group| all_tests(group) }
  end

  describe 'the fixtures' do
    it 'return a versioned adaptive Questionnaire from $questionnaire-package' do
      expect(package_fixture).to be_a(FHIR::Parameters)
      expect(package_questionnaire.url).to eq(canonical)
      expect(package_questionnaire.version).to eq('1.0.0')
      expect(package_questionnaire.title).to eq('Dinner Order (CQL Error)')
      expect(package_questionnaire.extension.find do |extension|
        extension.url == adaptive_url
      end.valueBoolean).to be(true)
    end

    it 'use a $next-question template with the same canonical' do
      expect(template_fixture).to be_a(FHIR::Questionnaire)
      expect(template_fixture.url).to eq(canonical)
      expect(template_fixture.version).to eq('1.0.0')
    end

    it 'put malformed CQL in a calculatedExpression on the item the stop test watches for' do
      error_item = all_items(template_fixture.item).find { |item| item.linkId == options[:cql_error_item_link_id] }
      calculated = error_item.extension.select { |extension| extension.url == calculated_expression_url }

      expect(calculated.length).to eq(1)
      expect(calculated.first.valueExpression.language).to eq('text/cql')
      expect(calculated.first.valueExpression.expression).to end_with('+')
      expect(all_items(template_fixture.item).flat_map(&:extension).count do |ext|
        ext.url == calculated_expression_url
      end)
        .to eq(1)
    end

    it 'only add the error item partway through the exchange, keeping its inclusion criteria' do
      error_item = all_items(template_fixture.item).find { |item| item.linkId == options[:cql_error_item_link_id] }

      expect(error_item.extension.map(&:url)).to include(inclusion_criteria_url)
    end

    it 'keep valid CQL pre-population logic so only the non-pre-population logic is problematic' do
      initial = all_items(template_fixture.item).flat_map(&:extension)
        .select { |extension| extension.url == initial_expression_url }

      expect(initial).to_not be_empty
      expect(initial.map { |extension| extension.valueExpression.language }.uniq).to eq(['text/cql'])
    end
  end

  describe 'group wiring' do
    it 'runs the interaction, package, next-question, and log errors tests, but not the completion tests' do
      test_ids = all_tests(described_class).map { |test| test.id.to_s }

      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_interaction_wait'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_cql_error_handling_attestation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_stopped_after_cql_error'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_log_errors_request_validation'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_ui_display_and_interaction'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_adaptive_questionnaires_completed'))
    end

    it 'tags the workflow, excludes it from must support coverage, and names the error item' do
      expect(options[:dtr_workflow_tag]).to eq('cql_error')
      expect(options[:dtr_exclude_from_questionnaire_must_support]).to be(true)
      expect(options[:qp_single_use]).to be(true)
      expect(options[:cql_error_item_link_id]).to eq('3.3')
      expect(options[:dtr_interaction_instructions]).to include('$log-questionnaire-errors')
      expect(options[:dtr_interaction_instructions]).to include('$next-question')
    end

    it 'is included in the Questionnaire Scenarios of the v2.2.0 client suite' do
      scenarios = DaVinciDTRTestKit::DTRFullEHRSuiteV220.groups
        .find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_questionnaire_workflows') }

      expect(scenarios.groups.map { |group| group.id.to_s })
        .to include(a_string_ending_with('dtr_full_ehr_v220_workflow_cql_error'))
    end
  end

  describe 'interaction wait instructions' do
    let(:client_id) { 'cql-error-spec-client' }
    let(:custom_instructions_test) do
      Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
        id :cql_error_custom_instructions_wait_spec_test
        config options: { dtr_interaction_instructions: "Stop the user.\nThen use the link below." }
      end
    end
    let(:default_instructions_test) do
      Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
        id :cql_error_default_instructions_wait_spec_test
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      [custom_instructions_test, default_instructions_test].each do |runnable|
        tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)
      end
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
    end

    it 'shows the configured instructions ahead of the continuation link and endpoint list' do
      result = run(custom_instructions_test, client_id:)

      expect(result.result).to eq('wait')
      expect(result.result_message).to match(/Stop the user\.\nThen use the link below\.\n\n\[Click here\]/)
      expect(result.result_message).to include('Log Questionnaire Errors Operation')
      expect(result.result_message).to_not include('completed and saved to the EHR')
    end

    it 'falls back to the default completion instructions' do
      result = run(default_instructions_test, client_id:)

      expect(result.result).to eq('wait')
      expect(result.result_message).to include('completed and saved to the EHR')
    end
  end
end
