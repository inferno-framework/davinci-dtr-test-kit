require 'davinci_dtr_test_kit/full_ehr/v2.2.0/cql_error/dtr_full_ehr_workflow_cql_error_group'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/cql_error/dtr_next_question_stopped_after_cql_error_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/package_questionnaire_templates'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/dtr_full_ehr_suite'
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

    it 'declare no meta.profile, so clients cannot depend on it' do
      contained = package_questionnaire_response.contained.find { |resource| resource.is_a?(FHIR::Questionnaire) }

      expect([template_fixture, package_questionnaire, contained].map(&:meta)).to all(be_nil)
    end

    it 'put malformed CQL in a calculatedExpression on the item the stop test watches for' do
      calculated = error_item.extension.select { |extension| extension.url == calculated_expression_url }

      expect(calculated.length).to eq(1)
      expect(calculated.first.valueExpression.language).to eq('text/cql')
      expect(calculated.first.valueExpression.expression).to end_with('+')
      expect(error_item.readOnly).to be(true)
      expect(error_item.required).to be(true)
    end

    it 'contain no pre-population logic, so the only CQL is the malformed calculatedExpression' do
      extensions = template_fixture.item.flat_map(&:extension)

      expect(extensions.map(&:url)).to_not include(initial_expression_url)
      expect(extensions.count { |extension| extension.valueExpression&.language == 'text/cql' }).to eq(1)
    end
  end

  describe 'group wiring' do
    it 'extends the standard adaptive group' do
      expect(described_class.superclass).to eq(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive)
      expect(described_class.groups.map(&:title))
        .to eq(['Interaction', '$questionnaire-package', '$next-question', '$log-questionnaire-errors'])
    end

    it 'keeps the package and next-question validation and adds the scenario tests' do
      test_ids = all_tests(described_class).map { |test| test.id.to_s }

      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_cql_error_interaction_wait'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_qp_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_response_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_nq_stopped_after_cql_error'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_log_errors_request_validation'))
      expect(test_ids).to include(a_string_ending_with('dtr_full_ehr_v220_log_errors_no_phi_attestation'))
    end

    it 'removes the rendering attestation and the completion check, which need a completed form' do
      test_ids = all_tests(described_class).map { |test| test.id.to_s }

      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_ui_display_and_interaction'))
      expect(test_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_adaptive_questionnaires_completed'))
      expect(test_ids.count { |id| id.end_with?('interaction_wait') }).to eq(1)
    end

    it 'leaves the standard adaptive group as it was' do
      adaptive_ids = all_tests(DaVinciDTRTestKit::DTRFullEHRV220AbstractAdaptive).map { |test| test.id.to_s }

      expect(adaptive_ids).to include(a_string_ending_with('dtr_full_ehr_v220_ui_display_and_interaction'))
      expect(adaptive_ids).to include(a_string_ending_with('dtr_full_ehr_v220_adaptive_questionnaires_completed'))
      expect(adaptive_ids).to_not include(a_string_ending_with('dtr_full_ehr_v220_nq_stopped_after_cql_error'))
    end

    it 'tags the workflow, excludes it from must support coverage, and replaces the wait instructions' do
      expect(options[:dtr_workflow_tag]).to eq('cql_error')
      expect(options[:dtr_exclude_from_questionnaire_must_support]).to be(true)
      expect(options[:qp_single_use]).to be(true)
      expect(options).to_not include(:interaction_message)
      expect(options[:interaction_attestation][:instructions]).to include("Inferno's CQL Error")
      expect(options[:interaction_attestation][:statement]).to include('prohibited further completion of the form')
      expect(options[:interaction_attestation].values.join).to_not include('PHI', '%<')
    end

    it 'links the two attestations and the mechanical checks to their requirements' do
      expect(find_test('dtr_full_ehr_v220_cql_error_interaction_wait').verifies_requirements)
        .to eq(['hl7.fhir.us.davinci-dtr_2.2.0@spec-81'])
      expect(find_test('dtr_full_ehr_v220_log_errors_no_phi_attestation').verifies_requirements)
        .to eq(['hl7.fhir.us.davinci-dtr_2.2.0@oper-2-B'])
      expect(find_test('dtr_full_ehr_v220_nq_stopped_after_cql_error').verifies_requirements)
        .to eq(['hl7.fhir.us.davinci-dtr_2.2.0@spec-81'])
      expect(find_test('dtr_full_ehr_v220_log_errors_request_validation').verifies_requirements)
        .to contain_exactly('hl7.fhir.us.davinci-dtr_2.2.0@oper-1', 'hl7.fhir.us.davinci-dtr_2.2.0@oper-3',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-78')
    end

    it 'is in the Error Handling group of the v2.2.0 client suite, not in Questionnaire Scenarios' do
      suite_groups = DaVinciDTRTestKit::DTRFullEHRSuiteV220.groups
      error_handling = suite_groups.find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_error_handling') }
      scenarios = suite_groups.find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_questionnaire_workflows') }

      expect(error_handling.groups.map { |group| group.id.to_s })
        .to include(a_string_ending_with('dtr_full_ehr_v220_workflow_cql_error'))
      expect(scenarios.groups.map { |group| group.id.to_s })
        .to_not include(a_string_ending_with('dtr_full_ehr_v220_workflow_cql_error'))
    end
  end

  describe 'the interaction wait' do
    let(:client_id) { 'cql-error-spec-client' }
    # The copy mounted in the suite, whose parent groups are registered.
    let(:wait_test) do
      error_handling = DaVinciDTRTestKit::DTRFullEHRSuiteV220.groups
        .find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_error_handling') }
      all_tests(error_handling).find { |test| test.id.to_s.end_with?('dtr_full_ehr_v220_cql_error_interaction_wait') }
    end

    before do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
    end

    it 'gives the scenario steps and asks for a true or false attestation in the standard format' do
      result = run(wait_test, client_id:)

      expect(result.result).to eq('wait')
      expect(result.result_message)
        .to start_with("Inferno will wait while the tester uses the system to begin completion of Inferno's CQL")
      expect(result.result_message).to include(
        "When you're done, attest to the following:\n\nI attest that the client notified the user that " \
        'there is an issue with the Questionnaire and prohibited further completion of the form.'
      )
      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_pass\?token=#{client_id}\) if the above statement is \*\*true\*\*})
      expect(result.result_message)
        .to match(%r{\[Click here\]\(\S+/resume_fail\?token=#{client_id}\) if the above statement is \*\*false\*\*})
      expect(result.result_message).to include("\n### Endpoints\n")
      expect(result.result_message).to include('Log Questionnaire Errors Operation')
      expect(result.result_message).to_not include('PHI')
      expect(result.result_message).to_not include('completed and saved to the EHR')
    end

    it 'keeps every line of the message out of markdown code-block indentation' do
      result = run(wait_test, client_id:)

      expect(result.result_message.lines.grep(/\A {4,}\S/)).to be_empty
    end
  end
end
