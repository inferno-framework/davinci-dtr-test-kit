# frozen_string_literal: true

module QuestionnaireDesignSpecHelpers
  def questionnaire_item(link_id: 'item-1', extensions: [], enable_when: [], items: [])
    FHIR::Questionnaire::Item.new(
      linkId: link_id,
      type: 'string',
      extension: extensions,
      enableWhen: enable_when,
      item: items
    )
  end

  def questionnaire(items: [], extensions: [])
    FHIR::Questionnaire.new(status: 'draft', item: items, extension: extensions)
  end

  def expression_extension(url, language: 'text/cql')
    FHIR::Extension.new(
      url:,
      valueExpression: FHIR::Expression.new(language:, expression: 'ExampleExpression')
    )
  end

  def questionnaire_package_response(*questionnaires)
    bundle = FHIR::Bundle.new(
      type: 'collection',
      entry: questionnaires.map { |resource| FHIR::Bundle::Entry.new(resource:) }
    )
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)]
    ).to_json
  end

  def next_question_response(questionnaire)
    FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [questionnaire]).to_json
  end

  def store_response(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])
    repo_create(
      :request,
      direction: 'outgoing',
      url: questionnaire_url,
      test_session_id: test_session.id,
      result:,
      request_body: '{}',
      response_body:,
      tags:,
      status: 200
    )
  end
end