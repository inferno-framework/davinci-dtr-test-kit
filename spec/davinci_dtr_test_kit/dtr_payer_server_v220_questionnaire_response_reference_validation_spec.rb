# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_response_reference_validation'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireResponseReferenceValidation do # rubocop:disable RSpec/SpecFilePathFormat
  let(:validator) do
    validation_module = described_class
    Class.new { include validation_module }.new
  end

  def questionnaire_response(attributes = {})
    FHIR::QuestionnaireResponse.new({ status: 'in-progress' }.merge(attributes))
  end

  it 'collects references and their locations from nested FHIR resources and arrays' do
    response = questionnaire_response(
      subject: FHIR::Reference.new(reference: 'Patient/example'),
      item: [FHIR::QuestionnaireResponse::Item.new(
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(
          valueReference: FHIR::Reference.new(reference: '#observation')
        )]
      )]
    )

    expected_references = [
      { value: 'Patient/example', location: 'subject.reference' },
      { value: '#observation', location: 'item[0].answer[0].valueReference.reference' }
    ]

    expect(validator.questionnaire_response_references(response)).to eq(expected_references)
  end

  it 'finds answer value references in nested items and nested answer items' do
    items = [FHIR::QuestionnaireResponse::Item.new(
      item: [FHIR::QuestionnaireResponse::Item.new(
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(
          valueReference: FHIR::Reference.new(reference: '#nested-item-answer')
        )]
      )],
      answer: [FHIR::QuestionnaireResponse::Item::Answer.new(
        item: [FHIR::QuestionnaireResponse::Item.new(
          answer: [FHIR::QuestionnaireResponse::Item::Answer.new(
            valueReference: FHIR::Reference.new(reference: '#nested-answer-item-answer')
          )]
        )]
      )]
    )]

    expected_locations = [
      'item[0].item[0].answer[0].valueReference.reference',
      'item[0].answer[0].item[0].answer[0].valueReference.reference'
    ]

    expect(validator.answer_value_reference_locations(items)).to eq(expected_locations)
  end

  it 'allows relative and client-endpoint references' do
    response = questionnaire_response(
      subject: FHIR::Reference.new(reference: 'Patient/example'),
      author: FHIR::Reference.new(reference: 'https://client.example/fhir/Practitioner/example')
    )

    expect(validator.invalid_questionnaire_response_references(response, 'https://client.example/fhir')).to be_empty
  end

  it 'allows references to resources contained in the QuestionnaireResponse' do
    response = questionnaire_response(
      contained: [FHIR::Patient.new(id: 'patient')],
      subject: FHIR::Reference.new(reference: '#patient')
    )

    expect(validator.invalid_questionnaire_response_references(response, nil)).to be_empty
  end

  it 'rejects a contained reference whose target is absent' do
    response = questionnaire_response(subject: FHIR::Reference.new(reference: '#missing'))

    expect(validator.invalid_questionnaire_response_references(response, nil))
      .to eq(['subject.reference references `#missing`'])
  end

  it 'rejects an absolute reference outside the client FHIR endpoint' do
    response = questionnaire_response(subject: FHIR::Reference.new(reference: 'https://payer.example/fhir/Patient/example'))

    expect(validator.invalid_questionnaire_response_references(response, 'https://client.example/fhir'))
      .to eq(['subject.reference references `https://payer.example/fhir/Patient/example`'])
  end

  it 'does not assess absolute references without a client FHIR endpoint' do
    response = questionnaire_response(subject: FHIR::Reference.new(reference: 'https://client.example/fhir/Patient/example'))

    expect(validator.invalid_questionnaire_response_references(response, nil)).to be_empty
    expect(validator.questionnaire_response_has_absolute_reference?(response)).to be(true)
  end

  it 'allows contained references only as answer value references' do
    response = questionnaire_response(
      contained: [FHIR::Observation.new(id: 'answer')],
      item: [FHIR::QuestionnaireResponse::Item.new(
        linkId: '1',
        answer: [
          FHIR::QuestionnaireResponse::Item::Answer.new(
            valueReference: FHIR::Reference.new(reference: '#answer')
          )
        ]
      )]
    )

    expect(validator.invalid_contained_reference_locations(response)).to be_empty
  end

  it 'rejects contained references outside answer value references' do
    response = questionnaire_response(
      contained: [FHIR::Patient.new(id: 'patient')],
      subject: FHIR::Reference.new(reference: '#patient')
    )

    expect(validator.invalid_contained_reference_locations(response))
      .to eq(['subject.reference references `#patient`'])
  end
end
