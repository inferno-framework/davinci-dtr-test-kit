require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_request_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:runnable) { find_test(suite, 'dtr_full_ehr_v220_nq_request_validation') }
  let(:next_url) { "#{Inferno::Application['base_url']}/custom/#{suite_id}#{DaVinciDTRTestKit::NEXT_PATH}" }
  let(:request_tags) { [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'adaptive'] }

  # The initial $next-question request: the contained Questionnaire has no items yet, so there are
  # no required questions to answer.
  let(:initial_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_conformant.json'))
  end

  # A follow-up $next-question request where every required question in the contained Questionnaire
  # has an answer.
  let(:all_answered_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_input_params_no_origin_extension.json'))
  end

  # A follow-up $next-question request that leaves out the optional `3` group, and with it the
  # required question `3.1` that the group holds.
  let(:missing_answer_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_input_params_missing_answer.json'))
  end

  # A follow-up $next-question request where top-level required question `Q1` has no answer.
  let(:unanswered_required_question_body) do
    request_body_for(
      questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
      response_items: []
    )
  end

  before do
    # Profile validation is exercised elsewhere and requires the validator service.
    allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
  end

  def build_next_requests(*request_bodies)
    result = repo_create(:result, test_session_id: test_session.id)
    request_bodies.each do |request_body|
      repo_create(:request, result_id: result.id, url: next_url, request_body:,
                            test_session_id: test_session.id, tags: request_tags)
    end
  end

  def result_messages_string
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first.messages.map(&:message).join("\n")
  end

  def fixture(name)
    FHIR.from_contents(File.read(File.join(__dir__, '..', 'fixtures', name)))
  end

  # Builds a $next-question request body containing a QuestionnaireResponse for a Questionnaire with
  # the provided items. When `wrap_in_parameters` is false the QuestionnaireResponse is the body.
  def request_body_for(questionnaire_items:, response_items:, wrap_in_parameters: true)
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      questionnaire: '#DinnerOrderAdaptive',
      contained: [
        FHIR::Questionnaire.new(
          id: 'DinnerOrderAdaptive',
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          item: questionnaire_items
        )
      ],
      item: response_items
    )
    return questionnaire_response.to_json unless wrap_in_parameters

    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: questionnaire_response)
      ]
    ).to_json
  end

  # Builds a request body from a Questionnaire and QuestionnaireResponse fixture pair by containing
  # the Questionnaire within the response, the way a client does for an adaptive form.
  def request_body_from_fixtures(questionnaire_name, response_name)
    questionnaire = fixture(questionnaire_name)
    questionnaire_response = fixture(response_name)
    questionnaire_response.contained = [questionnaire]
    questionnaire_response.questionnaire = "##{questionnaire.id}"
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: questionnaire_response)
      ]
    ).to_json
  end

  it 'skips if no $next-question request was made' do
    result = run(runnable)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('next-question request must be made prior to running this test')
  end

  it 'passes when the contained Questionnaire has no questions yet' do
    build_next_requests(initial_request_body)

    expect(run(runnable).result).to eq('pass')
  end

  it 'passes when all of the required questions have been answered' do
    build_next_requests(initial_request_body, all_answered_request_body)

    expect(run(runnable).result).to eq('pass')
  end

  it 'fails when a required question has not been answered' do
    build_next_requests(unanswered_required_question_body)

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
  end

  it 'identifies the request containing the unanswered required question' do
    build_next_requests(initial_request_body, unanswered_required_question_body)

    result = run(runnable)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Request 2:')
    expect(result_messages_string).to include('(Request 2) Item `Q1`')
  end

  # The groups in this fixture's contained Questionnaire are optional, and `required` on a nested
  # question only applies once its group is present, so the questions within the group that the
  # response leaves out do not need answers.
  it 'passes when the group holding an unanswered required question is absent and optional' do
    build_next_requests(missing_answer_request_body)

    expect(run(runnable).result).to eq('pass')
  end

  it 'fails when the group holding an unanswered required question is required' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [
          FHIR::Questionnaire::Item.new(
            linkId: 'Group1', type: 'group', required: true,
            item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
          )
        ],
        response_items: []
      )
    )

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to include('Item `Group1` is required and enabled, but has no answer')
  end

  it 'fails when a required question has not been answered in a bare QuestionnaireResponse body' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
        response_items: [],
        wrap_in_parameters: false
      )
    )

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
  end

  # Its absence is a violation of the adaptive QuestionnaireResponse profile, reported by the
  # profile validation rather than by the readiness check.
  it 'reports nothing about readiness when the QuestionnaireResponse does not contain a Questionnaire' do
    build_next_requests(
      FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'questionnaire-response',
            resource: FHIR::QuestionnaireResponse.new(status: 'in-progress')
          )
        ]
      ).to_json
    )

    expect(run(runnable).result).to eq('pass')
    expect(result_messages_string).to_not include('is required and enabled')
  end

  # A client is expected to send back the questions it was given, so the Questionnaire in each request
  # is compared against the one Inferno returned in the previous response.
  describe 'when the client alters the Questionnaire it was given' do
    def contained(items)
      FHIR::Questionnaire.new(
        id: 'DinnerOrderAdaptive', url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
        status: 'draft', item: items
      )
    end

    def response_body_returning(items)
      FHIR::QuestionnaireResponse.new(status: 'in-progress', questionnaire: '#DinnerOrderAdaptive',
                                      contained: [contained(items)]).to_json
    end

    # The first request carries what the payer returned; the second carries what the client sent back.
    def build_pair(returned_items, sent_items)
      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, url: next_url,
                            request_body: request_body_for(questionnaire_items: [], response_items: []),
                            response_body: response_body_returning(returned_items),
                            test_session_id: test_session.id, tags: request_tags)
      repo_create(:request, result_id: result.id, url: next_url,
                            request_body: request_body_for(questionnaire_items: sent_items, response_items: []),
                            test_session_id: test_session.id, tags: request_tags)
    end

    it 'passes when the client sends back the questions it was given' do
      build_pair([FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')],
                 [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')])

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when the client drops a required question' do
      build_pair([FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)], [])

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include(
        'Item `Q1` was returned by the payer but is missing from the Questionnaire in this request'
      )
    end

    it 'fails when the client turns a required question off with a condition' do
      returned = [FHIR::Questionnaire::Item.new(linkId: 'Q0', type: 'string'),
                  FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
      sent = [FHIR::Questionnaire::Item.new(linkId: 'Q0', type: 'string'),
              FHIR::Questionnaire::Item.new(
                linkId: 'Q1', type: 'string', required: true,
                enableWhen: [FHIR::Questionnaire::Item::EnableWhen.new(question: 'Q0', operator: '=',
                                                                       answerString: 'never')]
              )]
      build_pair(returned, sent)

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 2) Item `Q1` differs from the question the payer returned')
    end

    # The first request has no previous response, so it is compared against what $questionnaire-package
    # returned.
    def build_package_and_next_requests(questionnaire_items, *next_bodies)
      result = repo_create(:result, test_session_id: test_session.id)
      package_response = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'packagebundle',
            resource: FHIR::Bundle.new(
              type: 'collection',
              entry: [FHIR::Bundle::Entry.new(resource: contained(questionnaire_items))]
            )
          )
        ]
      ).to_json
      repo_create(:request, result_id: result.id,
                            url: "#{Inferno::Application['base_url']}/custom/#{suite_id}" \
                                 "#{DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH}",
                            request_body: '{}', response_body: package_response,
                            test_session_id: test_session.id,
                            tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'adaptive'])
      next_bodies.each do |request_body|
        repo_create(:request, result_id: result.id, url: next_url, request_body:,
                              test_session_id: test_session.id, tags: request_tags)
      end
    end

    it 'passes when the first request carries the Questionnaire the package returned' do
      build_package_and_next_requests(
        [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')],
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when the first request drops a question the package returned' do
      build_package_and_next_requests([FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
                                      request_body_for(questionnaire_items: [], response_items: []))

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include(
        'Item `Q1` was returned by the payer but is missing from the Questionnaire in this request'
      )
    end

    it 'fails when the first request invents a question the package never returned' do
      build_package_and_next_requests(
        [],
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Sneaky', type: 'string')],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include(
        'Item `Sneaky` is in the Questionnaire in this request but was not returned by the payer'
      )
    end

    it 'has nothing to compare against when no package request was made' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('pass')
    end
  end

  # Inferno cannot evaluate these expressions, so the test says so rather than guessing.
  describe 'when a question is enabled by an enableWhenExpression extension' do
    def expression_question(link_id, attributes = {})
      FHIR::Questionnaire::Item.new(
        {
          linkId: link_id, type: 'string',
          extension: [
            FHIR::Extension.new(
              url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
              valueExpression: FHIR::Expression.new(language: 'text/fhirpath', expression: 'true')
            )
          ]
        }.merge(attributes)
      )
    end

    it 'passes with an informational message when the question was not answered' do
      build_next_requests(
        request_body_for(questionnaire_items: [expression_question('Q1', required: true)], response_items: [])
      )

      expect(run(runnable).result).to eq('pass')
      expect(result_messages_string).to include(
        'Item `Q1` has an `enableWhenExpression` extension, which Inferno does not evaluate'
      )
    end

    it 'passes with an informational message when the question was answered' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [expression_question('Q1')],
          response_items: [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Q1',
              answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
            )
          ]
        )
      )

      expect(run(runnable).result).to eq('pass')
      expect(result_messages_string).to include('which Inferno does not evaluate')
    end

    it 'records the message as info rather than as an error' do
      build_next_requests(
        request_body_for(questionnaire_items: [expression_question('Q1', required: true)], response_items: [])
      )

      run(runnable)
      messages = results_repo
        .current_results_for_test_session_and_runnables(test_session.id, [runnable])
        .first.messages
      note = messages.find { |message| message.message.include?('enableWhenExpression') }

      expect(note.type).to eq('info')
    end
  end

  describe 'when answers and nested items are not where the item types say they belong' do
    it 'fails when a group carries answers of its own' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [
            FHIR::Questionnaire::Item.new(
              linkId: 'Group1', type: 'group',
              item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
            )
          ],
          response_items: [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Group1',
              answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'belongs to a question')],
              item: [
                FHIR::QuestionnaireResponse::Item.new(
                  linkId: 'Q1',
                  answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
                )
              ]
            )
          ]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Group1` is a group, so it must not have answers')
    end

    it 'fails when a question nests its items directly rather than within its answers' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [
            FHIR::Questionnaire::Item.new(
              linkId: 'Q1', type: 'string', required: true,
              item: [FHIR::Questionnaire::Item.new(linkId: 'Q1.1', type: 'string', required: true)]
            )
          ],
          response_items: [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Q1',
              answer: [
                FHIR::QuestionnaireResponse::Item::Answer.new(
                  valueString: 'an answer',
                  item: [
                    FHIR::QuestionnaireResponse::Item.new(
                      linkId: 'Q1.1',
                      answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'a nested answer')]
                    )
                  ]
                )
              ],
              item: [
                FHIR::QuestionnaireResponse::Item.new(
                  linkId: 'Q1.1',
                  answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'a misplaced answer')]
                )
              ]
            )
          ]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string)
        .to include('Item `Q1` is not a group, so its nested items must appear within its answers')
    end

    it 'reports each request that misplaces answers' do
      group_with_answers = request_body_for(
        questionnaire_items: [
          FHIR::Questionnaire::Item.new(
            linkId: 'Group1', type: 'group',
            item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
          )
        ],
        response_items: [
          FHIR::QuestionnaireResponse::Item.new(
            linkId: 'Group1',
            answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'belongs to a question')],
            item: [
              FHIR::QuestionnaireResponse::Item.new(
                linkId: 'Q1',
                answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
              )
            ]
          )
        ]
      )
      build_next_requests(initial_request_body, group_with_answers)

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to include('Request 2:')
      expect(result_messages_string).to include('(Request 2) Item `Group1` is a group')
    end
  end

  it 'passes when unanswered questions are not required' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: false)],
        response_items: []
      )
    )

    expect(run(runnable).result).to eq('pass')
  end

  describe 'when questions are gated by enableWhen conditions' do
    let(:trigger_question) { FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: false) }
    let(:gated_question) do
      FHIR::Questionnaire::Item.new(
        linkId: 'Q2', type: 'string', required: true,
        enableWhen: [
          FHIR::Questionnaire::Item::EnableWhen.new(question: 'Q1', operator: '=', answerString: 'no')
        ]
      )
    end

    def string_answer_item(link_id, value)
      FHIR::QuestionnaireResponse::Item.new(
        linkId: link_id,
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: value)]
      )
    end

    it 'passes when a required question is disabled by an unmet condition' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'yes')])
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when a required question is enabled by a met condition and unanswered' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'no')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Q2` is required and enabled, but has no answer')
    end

    it 'fails when a question that is not enabled has been answered' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'yes'), string_answer_item('Q2', 'an answer')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string)
        .to include('Item `Q2` has an answer, but is not enabled based on its `enableWhen` condition(s)')
    end
  end

  # These fixtures come from the example Karl put together for the enableWhen design, where the same
  # linkIds appear under each answer of a repeating question.
  describe 'when the same question is answered under several answers of a repeating question' do
    it 'passes when each answer holds the questions that its own value enables' do
      build_next_requests(
        request_body_from_fixtures('enable_when_multiple_parent_questionnaire.json',
                                   'enable_when_multiple_parent_valid_response.json')
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'reports the missing and misplaced answers against the answer they belong to' do
      build_next_requests(
        request_body_from_fixtures('enable_when_multiple_parent_questionnaire.json',
                                   'enable_when_multiple_parent_invalid_response.json')
      )

      expect(run(runnable).result).to eq('fail')
      messages = result_messages_string
      expect(messages).to include('Item `concern.other` within `concern[answer 1]` has an answer, but is not enabled')
      expect(messages).to include('Item `concern.contact` within `concern[answer 1]` has an answer, but is not enabled')
      expect(messages)
        .to include('Item `concern.other` within `concern[answer 2]` is required and enabled, but has no answer')
      expect(messages)
        .to include('Item `concern.contact` within `concern[answer 2]` is required and enabled, but has no answer')
    end
  end
end
