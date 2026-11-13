require 'davinci_dtr_test_kit/full_ehr/v2.2.0/answer_origin/dtr_full_ehr_workflow_answer_origin_group'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220WorkflowAnswerOrigin do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }

  # 2.3 as it is mounted in the suite, and its copy of the interaction wait test, which carries the
  # group's config.
  let(:mounted_group) do
    suite = Inferno::Repositories::TestSuites.new.find(suite_id)
    workflows_group = suite.groups.find { |group| group.id.to_s.end_with?('questionnaire_workflows') }
    workflows_group.groups.find { |group| group.id.to_s.end_with?('dtr_full_ehr_v220_workflow_answer_origin') }
  end
  let(:wait_test) do
    interaction_group = mounted_group.groups.first
    interaction_group.tests.find { |test| test.id.to_s.end_with?('dtr_full_ehr_v220_interaction_wait') }
  end

  let(:package_template) do
    DaVinciDTRTestKit::FixtureLoader.instance[wait_test.config.options[:qp_response_template_fixture]]
  end
  let(:next_question_template) do
    DaVinciDTRTestKit::FixtureLoader.instance[wait_test.config.options[:nq_questionnaire_template_fixture]]
  end

  it "uses Inferno's answer origin Questionnaire rather than tester-provided templates" do
    expect(wait_test.config.options[:qp_response_template_fixture])
      .to eq(File.join('answer_origin', 'answer_origin_questionnaire_package_response.json'))
    expect(wait_test.config.options[:nq_questionnaire_template_fixture])
      .to eq(File.join('answer_origin', 'answer_origin_adaptive_next_question_template.json'))
    # The group declares no template inputs of its own (client_id comes from the wait test).
    expect(mounted_group.inputs).to be_empty
  end

  it 'starts the interaction without any template inputs' do
    result = run(wait_test, { client_id: 'answer_origin_group_spec_client_id' })

    expect(result.result).to eq('wait'), result.result_message
    expect(result.result_message).to include("**Last Name (don't change!)**: leave the pre-populated last name")
    expect(result.result_message).to include('**By clicking to continue, you attest**')
    continue_link = %r{\[Click here\]\(\S+/resume_pass\?token=answer_origin_group_spec_client_id\)}
    expect(result.result_message).to match(/#{continue_link} to continue and attest\./)
  end

  it 'has a package placeholder that points to the $next-question template' do
    placeholder_canonicals = package_template.parameter.first.resource.entry.map do |entry|
      resource = entry.resource
      questionnaire = resource.is_a?(FHIR::QuestionnaireResponse) ? resource.contained.first : resource
      DaVinciDTRTestKit::InfernoControlExtensions.find_extension(
        questionnaire, DaVinciDTRTestKit::InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL
      ).valueCanonical
    end

    expect(placeholder_canonicals).to all(eq(next_question_template.url))
  end

  it 'asks the three questions, pre-populating the first two with FHIRPath and declaring the patient context' do
    items = next_question_template.item
    expect(items.map(&:linkId)).to eq(['last-name-do-not-change', 'preferred-first-name-update', 'new-information-add'])
    expect(items.map(&:text)).to eq(["Last Name (don't change!)", 'Preferred First Name (update)',
                                     'New Information (add details)'])
    expect(items.map(&:required)).to all(be(true))

    initial_expressions = items.map do |item|
      item.extension.find { |extension| extension.url.end_with?('sdc-questionnaire-initialExpression') }&.value
    end
    expect(initial_expressions[0].language).to eq('text/fhirpath')
    expect(initial_expressions[0].expression).to eq('%patient.name.first().family')
    expect(initial_expressions[1].language).to eq('text/fhirpath')
    expect(initial_expressions[1].expression).to eq('%patient.name.first().given.first()')
    expect(initial_expressions[2]).to be_nil

    launch_context = next_question_template.extension.find { |extension| extension.url.end_with?('launchContext') }
    expect(launch_context.extension.find { |part| part.url == 'name' }.value.code).to eq('patient')
    expect(next_question_template.extension.map(&:url)).to_not include('http://hl7.org/fhir/StructureDefinition/cqf-library')
  end
end
