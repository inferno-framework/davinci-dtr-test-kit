require 'davinci_dtr_test_kit/full_ehr/v2.2.0/cql_error/dtr_full_ehr_workflow_cql_error_group'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/cql_error/dtr_next_question_stopped_after_cql_error_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/package_questionnaire_templates'
require 'davinci_dtr_test_kit/full_ehr/fixture_loader'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowCQLError do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:options) { described_class.config.options }
  let(:package_fixture) { DaVinciDTRTestKit::FixtureLoader.instance[options[:qp_response_template_fixture]] }
  let(:template_fixture) { DaVinciDTRTestKit::FixtureLoader.instance[options[:nq_questionnaire_template_fixture]] }
  let(:package_bundle) { package_fixture.parameter.find { |param| param.name == 'packagebundle' }.resource }
  let(:package_questionnaire) do
    package_bundle.entry.map(&:resource).find { |resource| resource.is_a?(FHIR::Questionnaire) }
  end
  let(:package_questionnaire_response) do
    package_bundle.entry.map(&:resource).find { |resource| resource.is_a?(FHIR::QuestionnaireResponse) }
  end
  let(:canonical) { 'urn:inferno:dtr-test-kit:cql-error-adaptive' }
  let(:placeholder_url) { DaVinciDTRTestKit::InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL }
  let(:adaptive_url) { DaVinciDTRTestKit::PackageQuestionnaireTemplates::QUESTIONNAIRE_ADAPTIVE_URL }
  let(:calculated_expression_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression' }
  let(:initial_expression_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression' }
  let(:inclusion_criteria_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUSION_CRITERIA_URL }
  let(:error_link_id) { DaVinciDTRTestKit::DTRFullEHRV220NextQuestionStoppedAfterCQLErrorTest::CQL_ERROR_ITEM_LINK_ID }
  let(:error_item) { template_fixture.item.find { |item| item.linkId == error_link_id } }

  def all_tests(runnable)
    runnable.tests + runnable.groups.flat_map { |group| all_tests(group) }
  end

  def find_test(suffix)
    all_tests(described_class).find { |test| test.id.to_s.end_with?(suffix) }
  end

  def placeholder_canonical(questionnaire)
    questionnaire.extension.find { |extension| extension.url == placeholder_url }&.valueCanonical
  end

  describe 'the fixtures' do
    it 'build the package Questionnaire from the $next-question template, in a collection Bundle with fullUrls' do
      expect(package_fixture).to be_a(FHIR::Parameters)
      expect(package_bundle.type).to eq('collection')
      expect(package_bundle.entry.map(&:fullUrl)).to all(start_with('urn:uuid:'))
      expect(placeholder_canonical(package_questionnaire)).to eq(canonical)
      expect(package_questionnaire.meta.profile)
        .to eq(['http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt-search'])
    end

    it 'include an in-progress QuestionnaireResponse that contains the same placeholder Questionnaire' do
      contained = package_questionnaire_response.contained.find { |resource| resource.is_a?(FHIR::Questionnaire) }

      expect(package_questionnaire_response.status).to eq('in-progress')
      expect(package_questionnaire_response.questionnaire).to eq("##{contained.id}")
      expect(placeholder_canonical(contained)).to eq(canonical)
      expect(contained.derivedFrom).to eq(["#{canonical}|1.0.0"])
      expect(package_questionnaire_response.extension.map(&:url))
        .to include('http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-coverage',
                    'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/intendedUse')
    end

    it 'use a versioned two-stage $next-question template whose questionnaireAdaptive is a valueUrl' do
      adaptive = template_fixture.extension.find { |extension| extension.url == adaptive_url }

      expect(template_fixture).to be_a(FHIR::Questionnaire)
      expect(template_fixture.url).to eq(canonical)
      expect(template_fixture.version).to eq('1.0.0')
      expect(template_fixture.meta.profile)
        .to eq(['http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt'])
      expect(adaptive.valueUrl).to be_present
      expect(adaptive.valueBoolean).to be_nil
      expect(template_fixture.item.map(&:linkId)).to eq(['1', '2'])
    end

    it 'ask for one manually entered answer first, with no expressions on that item' do
      first = template_fixture.item.first

      expect(first.type).to eq('string')
      expect(first.required).to be(true)
      expect(first.extension).to be_empty
      expect(first.item).to be_empty
    end

    it 'add the error item only after the first answer, keeping its inclusion criteria' do
      criteria = error_item.extension.find { |extension| extension.url == inclusion_criteria_url }

      expect(criteria.valueExpression.expression).to include("linkId = '1'")
    end

    it 'put malformed CQL in a calculatedExpression on the item the stop test watches for' do
      calculated = error_item.extension.select { |extension| extension.url == calculated_expression_url }

      expect(calculated.length).to eq(1)
      expect(calculated.first.valueExpression.language).to eq('text/cql')
      expect(calculated.first.valueExpression.expression).to end_with('+')
      expect(error_item.readOnly).to be(true)
    end

    it 'contain no pre-population logic, so the only CQL is the malformed calculatedExpression' do
      extensions = template_fixture.item.flat_map(&:extension)

      expect(extensions.map(&:url)).to_not include(initial_expression_url)
      expect(extensions.count { |extension| extension.valueExpression&.language == 'text/cql' }).to eq(1)
    end
  end

  describe 'group wiring' do
    it 'runs the interaction, package, next-question, and log errors tests, but no attestation or completion test' do
      test_ids = all_tests(described_class).map { |test| test.id.to_s }

      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_interaction_wait'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_stopped_after_cql_error'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_log_errors_request_validation'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_cql_error_handling_attestation'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_ui_display_and_interaction'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_adaptive_questionnaires_completed'))
    end

    it 'tags the workflow, excludes it from must support coverage, and replaces the wait instructions' do
      expect(options[:dtr_workflow_tag]).to eq('cql_error')
      expect(options[:dtr_exclude_from_questionnaire_must_support]).to be(true)
      expect(options[:qp_single_use]).to be(true)
      expect(options[:interaction_message])
        .to include('$log-questionnaire-errors', '**By clicking to continue, you attest**', '%<continuation_url>s')
      expect(options).to_not include(:dtr_interaction_instructions, :cql_error_item_link_id)
    end

    it 'links the attestation points on the wait and the mechanical checks to their requirements' do
      expect(find_test('dtr_full_ehr_v220_interaction_wait').verifies_requirements)
        .to contain_exactly('hl7.fhir.us.davinci-dtr_2.2.0@spec-81', 'hl7.fhir.us.davinci-dtr_2.2.0@oper-2-B')
      expect(find_test('dtr_full_ehr_v220_nq_stopped_after_cql_error').verifies_requirements)
        .to eq(['hl7.fhir.us.davinci-dtr_2.2.0@spec-81'])
      expect(find_test('dtr_full_ehr_v220_log_errors_request_validation').verifies_requirements)
        .to contain_exactly('hl7.fhir.us.davinci-dtr_2.2.0@oper-1', 'hl7.fhir.us.davinci-dtr_2.2.0@oper-3',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-78')
    end

    it 'is included in the Questionnaire Scenarios of the v2.2.0 client suite' do
      scenarios = DaVinciDTRTestKit::DTRFullEHRSuiteV220.groups
        .find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_questionnaire_workflows') }

      expect(scenarios.groups.map { |group| group.id.to_s })
        .to include(a_string_ending_with('dtr_full_ehr_v220_workflow_cql_error'))
    end
  end

  describe 'the interaction wait' do
    let(:client_id) { 'cql-error-spec-client' }
    let(:wait_test) { find_test('dtr_full_ehr_v220_interaction_wait') }

    before do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
    end

    it 'asks the tester to stop at the CQL error and attest, then lists the endpoints' do
      result = run(wait_test, client_id:)

      expect(result.result).to eq('wait')
      expect(result.result_message)
        .to start_with("Inferno will wait while the tester uses the system to retrieve Inferno's CQL Error")
      expect(result.result_message).to include('**By clicking to continue, you attest**')
      expect(result.result_message).to match(%r{\[click here\]\(\S+/resume_pass\?token=#{client_id}\)})
      expect(result.result_message).to include("\n### Endpoints\n")
      expect(result.result_message).to include('Log Questionnaire Errors Operation')
      expect(result.result_message).to_not include('completed and saved to the EHR')
    end

    it 'keeps every line of the message out of markdown code-block indentation' do
      result = run(wait_test, client_id:)

      expect(result.result_message.lines.grep(/\A {4,}\S/)).to be_empty
    end
  end
end
