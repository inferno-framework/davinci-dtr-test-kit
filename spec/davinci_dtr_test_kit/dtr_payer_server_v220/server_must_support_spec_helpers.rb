module ServerMustSupportSpecHelpers
  def prior_result
    @prior_result ||= repo_create(:result, test_session_id: test_session.id)
  end

  def store_must_support_response(response_body, url: questionnaire_package_url,
                                  tag: DaVinciDTRTestKit::QUESTIONNAIRE_TAG)
    repo_create(
      :request,
      direction: 'outgoing',
      url:,
      test_session_id: test_session.id,
      result: prior_result,
      response_body:,
      tags: [tag],
      status: 200
    )
  end

  def questionnaire_package_url
    'https://payer.example.com/fhir/Questionnaire/$questionnaire-package'
  end

  def next_question_url
    'https://payer.example.com/fhir/Questionnaire/$next-question'
  end

  def questionnaire_package_bundle(*resources)
    FHIR::Bundle.new(
      type: 'collection',
      entry: resources.map { |resource| FHIR::Bundle::Entry.new(resource:) }
    )
  end

  def questionnaire_package_response(*bundles)
    FHIR::Parameters.new(
      parameter: bundles.map do |bundle|
        FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)
      end
    ).to_json
  end

  def next_question_response(questionnaire)
    FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [questionnaire]).to_json
  end

  def standard_questionnaire(id: 'standard')
    FHIR::Questionnaire.new(
      id:,
      status: 'active',
      item: [
        FHIR::Questionnaire::Item.new(
          linkId: 'standard-item',
          type: 'string',
          enableWhen: [FHIR::Questionnaire::Item::EnableWhen.new(
            question: 'prior-item',
            operator: 'exists',
            answerBoolean: true
          )],
          extension: [FHIR::Extension.new(
            url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
            valueExpression: FHIR::Expression.new(language: 'text/fhirpath', expression: 'true')
          )]
        )
      ]
    )
  end

  def adaptive_questionnaire(id: 'adaptive')
    FHIR::Questionnaire.new(
      id:,
      status: 'active',
      extension: [FHIR::Extension.new(
        url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
        valueBoolean: true
      )],
      item: [
        FHIR::Questionnaire::Item.new(
          linkId: 'adaptive-item',
          type: 'string',
          enableWhen: [FHIR::Questionnaire::Item::EnableWhen.new(
            question: 'prior-item',
            operator: 'exists',
            answerBoolean: true
          )]
        )
      ]
    )
  end

  def capture_asserted_resources(test_class)
    captured_resources = []
    allow_any_instance_of(test_class).to receive(:assert_must_support_elements_present) do |_test, resources, *, **|
      captured_resources.concat(resources)
    end
    captured_resources
  end
end
