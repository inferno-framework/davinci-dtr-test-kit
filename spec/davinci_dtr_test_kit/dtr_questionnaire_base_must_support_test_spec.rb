RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnaireBaseMustSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:tags) { [DaVinciDTRTestKit::CLIENT_QUESTIONNAIRE_MUST_SUPPORT] }

  def create_tagged_request(response_body, url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
                            extra_tags: [])
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags: tags + extra_tags,
      status: 200
    )
  end

  # Every must support element, extension, and slice defined on the DTR Base Questionnaire
  # profile (lib/davinci_dtr_test_kit/cross_suite/generated/v2.2.0/dtr_base_questionnaire/metadata.yml),
  # populated on a single Questionnaire.item so a single resource satisfies the whole profile.
  #
  # Built as a plain Hash (rather than FHIR::Model objects) because fhir_models only tracks
  # primitive extensions (eg the `_text` sibling below) in a parse-time cache (`source_hash`);
  # it does not round-trip them back out through `#to_json`. Wrapping this in other FHIR::Model
  # objects and re-serializing would silently drop them, so the whole response body is built and
  # serialized as one Hash instead.
  def conformant_base_questionnaire
    {
      resourceType: 'Questionnaire',
      url: 'http://example.org/Questionnaire/conformant',
      version: '1.0.0',
      title: 'Conformant Questionnaire',
      status: 'active',
      subjectType: ['Patient'],
      effectivePeriod: { start: '2024-01-01' },
      extension: [
        { url: 'http://hl7.org/fhir/StructureDefinition/preferredTerminologyServer',
          valueUrl: 'http://example.org/fhir' },
        { url: 'http://hl7.org/fhir/StructureDefinition/artifact-versionAlgorithm', valueString: '1.0.0' },
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-performerType',
          valueCodeableConcept: { coding: [{ system: 'http://snomed.info/sct', code: '158965000' }] } },
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assemble-expectation',
          valueCode: 'assemble-root' },
        { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/estimated-completion-time',
          valueDuration: { value: 5, unit: 'minutes', system: 'http://unitsofmeasure.org', code: 'min' } },
        { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/questionnaireAudience',
          valueCodeableConcept: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/v2-0912',
                                             code: 'PROV' }] } },
        { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/request-specific', valueBoolean: true },
        { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-signatureRequired', valueBoolean: false },
        { url: 'http://hl7.org/fhir/StructureDefinition/variable',
          valueExpression: { name: 'someVar', language: 'text/cql', expression: 'true' } },
        { url: 'http://hl7.org/fhir/StructureDefinition/cqf-library', valueCanonical: 'http://example.org/Library/x' },
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext',
          extension: [
            { url: 'name', valueId: 'patient' },
            { url: 'type', valueCode: 'Patient' }
          ] },
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext',
          valueExpression: { language: 'text/cql', expression: 'true' } },
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-entryMode', valueCode: 'prepopulated' }
      ],
      item: [
        {
          linkId: 'Q1',
          prefix: '1.',
          text: 'Conformant question',
          _text: {
            extension: [
              { url: 'http://hl7.org/fhir/StructureDefinition/rendering-xhtml',
                valueString: '<div xmlns="http://www.w3.org/1999/xhtml">Conformant question</div>' }
            ]
          },
          type: 'choice',
          enableBehavior: 'all',
          required: true,
          repeats: false,
          readOnly: false,
          answerValueSet: 'http://example.org/ValueSet/answers',
          answerOption: [
            { valueCoding: { system: 'http://example.org/CodeSystem/answers', code: 'yes' } },
            {
              valueReference: {
                reference: 'Patient/1',
                extension: [
                  { url: 'http://hl7.org/fhir/StructureDefinition/rendering-xhtml',
                    valueString: '<div xmlns="http://www.w3.org/1999/xhtml">Patient</div>' }
                ]
              },
              extension: [
                { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive', valueBoolean: false }
              ]
            }
          ],
          initial: [
            { valueReference: { reference: 'Patient/1' } }
          ],
          item: [
            { linkId: 'Q1.1', type: 'string' }
          ],
          extension: [
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-hidden', valueBoolean: false },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-itemControl',
              valueCodeableConcept: { coding: [{ system: 'http://hl7.org/fhir/questionnaire-item-control',
                                                 code: 'radio-button' }] } },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-supportHyperlink',
              valueUrl: 'http://example.org/help' },
            { url: 'http://hl7.org/fhir/StructureDefinition/mimeType', valueCode: 'text/plain' },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-unitOption',
              valueCoding: { system: 'http://unitsofmeasure.org', code: 'min' } },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-referenceResource',
              valueReference: { reference: 'Patient/1' } },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-referenceProfile',
              valueCanonical: 'http://hl7.org/fhir/StructureDefinition/Patient' },
            { url: 'http://hl7.org/fhir/StructureDefinition/questionnaire-unitValueSet',
              valueCanonical: 'http://example.org/ValueSet/units' },
            { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-lookupQuestionnaire',
              valueCanonical: 'http://example.org/Questionnaire/lookup' },
            { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression',
              valueExpression: {
                language: 'text/cql', expression: 'CandidateExpr',
                extension: [
                  { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
                    valueExpression: { language: 'text/fhirpath', expression: 'true' } }
                ]
              } },
            { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
              valueExpression: {
                language: 'text/cql', expression: 'InitialExpr',
                extension: [
                  { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
                    valueExpression: { language: 'text/fhirpath', expression: 'true' } }
                ]
              } },
            { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
              valueExpression: {
                language: 'text/cql', expression: 'CalculatedExpr',
                extension: [
                  { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
                    valueExpression: { language: 'text/fhirpath', expression: 'true' } }
                ]
              } },
            { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression',
              extension: [
                { url: 'expression',
                  valueExpression: {
                    language: 'text/cql', expression: 'ContextExpr',
                    extension: [
                      { url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
                        valueExpression: { language: 'text/fhirpath', expression: 'true' } }
                    ]
                  } }
              ] }
          ]
        }
      ]
    }
  end

  def questionnaire_response_json(questionnaire_hash)
    { resourceType: 'QuestionnaireResponse', status: 'in-progress', contained: [questionnaire_hash] }.to_json
  end

  def next_question_output_json(questionnaire_hash)
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'return', resource: { resourceType: 'QuestionnaireResponse', status: 'in-progress',
                                      contained: [questionnaire_hash] } }
      ]
    }.to_json
  end

  def questionnaire_package_output_json(questionnaire_hash)
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      ]
    }.to_json
  end

  it 'skips when no requests have been made' do
    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Requests must be made/)
  end

  it 'skips when the tagged requests contain no Questionnaires' do
    create_tagged_request({ resourceType: 'QuestionnaireResponse', status: 'in-progress' }.to_json)

    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Questionnaires found/)
  end

  it 'ignores requests that are not valid JSON' do
    create_tagged_request('not valid json')

    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Questionnaires found/)
  end

  it 'fails and lists the missing elements when the Questionnaire is missing must support elements' do
    create_tagged_request(questionnaire_response_json({ resourceType: 'Questionnaire', status: 'active' }))

    result = run(described_class)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Could not find/)
    expect(result.result_message).to include('Questionnaire.extension:terminologyServer')
  end

  it 'passes when a fully conformant Questionnaire is contained in a QuestionnaireResponse' do
    create_tagged_request(questionnaire_response_json(conformant_base_questionnaire))

    result = run(described_class)
    expect(result.result).to eq('pass'), result.result_message
  end

  it 'extracts Questionnaires from a $next-question output Parameters response' do
    create_tagged_request(next_question_output_json(conformant_base_questionnaire))

    result = run(described_class)
    expect(result.result).to eq('pass'), result.result_message
  end

  it 'extracts Questionnaires from a $questionnaire-package output Parameters response' do
    create_tagged_request(
      questionnaire_package_output_json(conformant_base_questionnaire),
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package'
    )

    result = run(described_class)
    expect(result.result).to eq('pass'), result.result_message
  end
end
