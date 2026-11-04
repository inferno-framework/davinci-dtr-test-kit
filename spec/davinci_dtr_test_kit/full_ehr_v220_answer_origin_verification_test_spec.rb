require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/answer_origin_verification_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220AnswerOriginVerificationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  let(:information_origin_url) { 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin' }
  let(:initial_expression_url) { 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression' }

  # Two pre-populated items (LastName, FirstName) and one item that is not pre-populated (Dinner)
  let(:questionnaire) do
    prepopulated_extension = [{ url: initial_expression_url,
                                valueExpression: { language: 'text/cql', expression: '"DTRTest".Name' } }]
    {
      resourceType: 'Questionnaire',
      status: 'active',
      url: 'http://example.org/Questionnaire/answer-origin',
      extension: [
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true }
      ],
      item: [
        {
          linkId: 'Patient',
          type: 'group',
          item: [
            { linkId: 'LastName', type: 'string', extension: prepopulated_extension },
            { linkId: 'FirstName', type: 'string', extension: prepopulated_extension }
          ]
        },
        { linkId: 'Dinner', type: 'string' }
      ]
    }
  end

  let(:expected_questionnaire_response) do
    questionnaire_response(last_name_source: 'auto-client', first_name_source: 'override', dinner_source: 'manual')
  end

  # Results returned directly by `run` don't carry their messages, so reload them from the session.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def answer(value, source)
    answer = { valueString: value }
    unless source.nil?
      answer[:extension] = [{ url: information_origin_url, extension: [{ url: 'source', valueCode: source }] }]
    end
    answer
  end

  def questionnaire_response(last_name_source:, first_name_source:, dinner_source:)
    {
      resourceType: 'QuestionnaireResponse',
      status: 'in-progress',
      contained: [questionnaire],
      item: [
        {
          linkId: 'Patient',
          item: [
            { linkId: 'LastName', answer: [answer('Smith', last_name_source)] },
            { linkId: 'FirstName', answer: [answer('Jo', first_name_source)] }
          ]
        },
        { linkId: 'Dinner', answer: [answer('Pizza', dinner_source)] }
      ]
    }
  end

  def create_nq_request(request_questionnaire_response, response_status: 'completed',
                        tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG])
    response_questionnaire_response = request_questionnaire_response.merge(status: response_status)
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
      test_session_id: test_session.id,
      result:,
      request_body: request_questionnaire_response.to_json,
      response_body: response_questionnaire_response.to_json,
      tags:,
      status: 200
    )
  end

  it 'passes when there are override, auto-client, and manual answers on the expected items' do
    create_nq_request(expected_questionnaire_response)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'accepts a request with the QuestionnaireResponse wrapped in Parameters' do
    parameters = {
      resourceType: 'Parameters',
      parameter: [{ name: 'questionnaire-response', resource: expected_questionnaire_response }]
    }
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
      test_session_id: test_session.id,
      result:,
      request_body: parameters.to_json,
      response_body: expected_questionnaire_response.merge(status: 'completed').to_json,
      tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG],
      status: 200
    )

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'skips when no $next-question request was made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('A $next-question request must be made prior to running this test.')
  end

  it 'skips when no $next-question request resulted in a completed QuestionnaireResponse' do
    create_nq_request(expected_questionnaire_response, response_status: 'in-progress')

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No $next-question request resulted in a completed QuestionnaireResponse')
  end

  it 'checks the answers from the last completed request, ignoring earlier in-progress requests' do
    earlier = questionnaire_response(last_name_source: 'auto-client', first_name_source: 'auto-client',
                                     dinner_source: nil)
    create_nq_request(earlier, response_status: 'in-progress')
    create_nq_request(expected_questionnaire_response)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when an answer is missing the information-origin source' do
    create_nq_request(
      questionnaire_response(last_name_source: 'auto-client', first_name_source: 'override', dinner_source: nil)
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'Answer to item `Dinner` is missing an information-origin extension with a `source`.'
    )
  end

  it 'fails when a pre-populated item has a manual source' do
    create_nq_request(
      questionnaire_response(last_name_source: 'manual', first_name_source: 'override', dinner_source: 'manual')
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'Answer to pre-populated item `LastName` has information-origin source `manual`, ' \
      'expected one of: auto-client, auto-server, override.'
    )
  end

  it 'fails when an item that is not pre-populated has an auto-client source' do
    create_nq_request(
      questionnaire_response(last_name_source: 'auto-client', first_name_source: 'override',
                             dinner_source: 'auto-client')
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'Answer to item that is not pre-populated `Dinner` has information-origin source `auto-client`, ' \
      'expected one of: manual.'
    )
  end

  it 'fails when no pre-populated answer was overridden' do
    create_nq_request(
      questionnaire_response(last_name_source: 'auto-client', first_name_source: 'auto-client',
                             dinner_source: 'manual')
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_including('No pre-populated answer was changed by the user'))
  end

  it 'fails when no pre-populated answer was left unchanged' do
    create_nq_request(
      questionnaire_response(last_name_source: 'override', first_name_source: 'override', dinner_source: 'manual')
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_including('No pre-populated answer was left unchanged'))
  end

  it 'does not count an auto-server answer as leaving a pre-populated answer unchanged' do
    create_nq_request(
      questionnaire_response(last_name_source: 'auto-server', first_name_source: 'override', dinner_source: 'manual')
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_including('No pre-populated answer was left unchanged'))
  end

  it 'fails when no answer was filled in manually' do
    response = questionnaire_response(last_name_source: 'auto-client', first_name_source: 'override',
                                      dinner_source: 'manual')
    response[:item].pop
    create_nq_request(response)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_including('No answer was filled in manually'))
  end

  it 'checks items nested beneath answers' do
    response = questionnaire_response(last_name_source: 'auto-client', first_name_source: 'override',
                                      dinner_source: 'manual')
    questionnaire[:item] << { linkId: 'Toppings', type: 'string' }
    response[:item].last[:answer].first[:item] = [{ linkId: 'Toppings', answer: [answer('Cheese', 'auto-client')] }]
    create_nq_request(response)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'Answer to item that is not pre-populated `Toppings` has information-origin source `auto-client`, ' \
      'expected one of: manual.'
    )
  end

  it 'only considers requests tagged for the configured workflow' do
    scoped_test_class = Class.new(described_class) do
      id :scoped_answer_origin_verification_spec_test
      config options: { dtr_workflow_tag: 'answer_origin' }
    end
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    create_nq_request(expected_questionnaire_response, tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'other_workflow'])

    result = run(scoped_test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('A $next-question request must be made prior to running this test.')
  end
end
