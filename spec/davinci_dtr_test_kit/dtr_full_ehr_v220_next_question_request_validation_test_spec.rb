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

  # The answers are judged against the Questionnaire Inferno returned, not the copy in the request, so
  # a client that mangles its copy still owes the answers Inferno asked for.
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
    def build_pair(returned_items, sent_items, response_items: [])
      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, url: next_url,
                            request_body: request_body_for(questionnaire_items: [], response_items: []),
                            response_body: response_body_returning(returned_items),
                            test_session_id: test_session.id, tags: request_tags)
      repo_create(:request, result_id: result.id, url: next_url,
                            request_body: request_body_for(questionnaire_items: sent_items,
                                                           response_items:),
                            test_session_id: test_session.id, tags: request_tags)
    end

    it 'passes when the questions Inferno returned have been answered' do
      question = FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)
      build_pair([question], [question], response_items: [
                   FHIR::QuestionnaireResponse::Item.new(
                     linkId: 'Q1',
                     answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
                   )
                 ])

      expect(run(runnable).result).to eq('pass')
    end

    it 'still expects an answer to a required question the client dropped from its copy' do
      build_pair([FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)], [])

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 2) Item `Q1` is required and enabled, but has no answer')
    end

    it 'still expects an answer to a required question the client turned off with a condition' do
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
      expect(result_messages_string).to include('(Request 2) Item `Q1` is required and enabled, but has no answer')
    end

    # The first request has no previous response, so it is judged against what $questionnaire-package
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

    it 'still expects an answer to a required question the first request dropped from its copy' do
      build_package_and_next_requests([FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
                                      request_body_for(questionnaire_items: [], response_items: []))

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
    end

    it 'passes when the first request answers what the package asked for' do
      build_package_and_next_requests(
        [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
          response_items: [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Q1',
              answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
            )
          ]
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'falls back to the contained Questionnaire when Inferno has nothing on record' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
    end
  end

  # A tester may work through more than one adaptive Questionnaire during a single interaction, so
  # the response to compare a request against is found by searching backwards for one that returned
  # the same Questionnaire.
  describe 'when choosing the earlier response to compare a request against' do
    def adaptive_questionnaire(url, version, items)
      FHIR::Questionnaire.new(id: 'Adaptive', url:, version:, status: 'draft', item: items)
    end

    def required_question(link_id)
      FHIR::Questionnaire::Item.new(linkId: link_id, type: 'string', required: true)
    end

    def answered(link_id)
      FHIR::QuestionnaireResponse::Item.new(
        linkId: link_id,
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
      )
    end

    def request_for(url, version, items: [], response_items: [])
      FHIR::QuestionnaireResponse.new(status: 'in-progress', questionnaire: '#Adaptive',
                                      contained: [adaptive_questionnaire(url, version, items)],
                                      item: response_items).to_json
    end

    def response_returning(url, version, items, status: 'in-progress')
      FHIR::QuestionnaireResponse.new(status:, questionnaire: '#Adaptive',
                                      contained: [adaptive_questionnaire(url, version, items)]).to_json
    end

    def package_returning(url, version, items)
      FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'packagebundle',
            resource: FHIR::Bundle.new(
              type: 'collection',
              entry: [FHIR::Bundle::Entry.new(resource: adaptive_questionnaire(url, version, items))]
            )
          )
        ]
      ).to_json
    end

    # Each exchange is a [request body, response body] pair, recorded in order under one result the
    # way a live interaction records them.
    def build_exchanges(exchanges, package: nil)
      result = repo_create(:result, test_session_id: test_session.id)
      if package.present?
        repo_create(:request, result_id: result.id,
                              url: "#{Inferno::Application['base_url']}/custom/#{suite_id}" \
                                   "#{DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH}",
                              request_body: '{}', response_body: package,
                              test_session_id: test_session.id,
                              tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'adaptive'])
      end
      exchanges.each do |request_body, response_body|
        repo_create(:request, result_id: result.id, url: next_url, request_body:, response_body:,
                              test_session_id: test_session.id, tags: request_tags)
      end
    end

    let(:first_url) { 'urn:inferno:dtr-test-kit:adaptive-one' }
    let(:second_url) { 'urn:inferno:dtr-test-kit:adaptive-two' }

    it 'looks past a response that returned a different Questionnaire' do
      build_exchanges(
        [
          [request_for(first_url, nil), response_returning(first_url, nil, [required_question('Q1')])],
          [request_for(second_url, nil), response_returning(second_url, nil, [])],
          [request_for(first_url, nil), nil]
        ]
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 3) Item `Q1` is required and enabled, but has no answer')
    end

    it 'ignores a response that returned a different version of the same Questionnaire' do
      build_exchanges(
        [
          [request_for(first_url, '1.0.0'), response_returning(first_url, '1.0.0', [required_question('Q1')])],
          [request_for(first_url, '2.0.0'), nil]
        ],
        package: package_returning(first_url, '2.0.0', [required_question('Q2')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 2) Item `Q2` is required and enabled, but has no answer')
      expect(result_messages_string).to_not include('Item `Q1`')
    end

    # Completing a Questionnaire and then asking for a next question again starts it over, so the
    # request is compared against what $questionnaire-package returned.
    it 'starts over from the package response when the previous response completed the Questionnaire' do
      build_exchanges(
        [
          [request_for(first_url, nil, response_items: [answered('Q0')]),
           response_returning(first_url, nil, [required_question('Q1')], status: 'completed')],
          [request_for(first_url, nil), nil]
        ],
        package: package_returning(first_url, nil, [required_question('Q0')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 2) Item `Q0` is required and enabled, but has no answer')
      expect(result_messages_string).to_not include('Item `Q1`')
    end

    it 'matches an earlier response on url alone when the request Questionnaire has no version' do
      build_exchanges(
        [
          [request_for(first_url, '1.0.0'), response_returning(first_url, '1.0.0', [required_question('Q1')])],
          [request_for(first_url, nil), nil]
        ]
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('(Request 2) Item `Q1` is required and enabled, but has no answer')
    end

    it 'does not use a packaged Questionnaire whose version differs from the request' do
      build_exchanges(
        [[request_for(first_url, '2.0.0'), nil]],
        package: package_returning(first_url, '1.0.0', [required_question('Q1')])
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'uses a packaged Questionnaire whose version matches the request' do
      build_exchanges(
        [[request_for(first_url, '2.0.0'), nil]],
        package: package_returning(first_url, '2.0.0', [required_question('Q1')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
    end

    it 'uses a packaged Questionnaire of any version when the request names none' do
      build_exchanges(
        [[request_for(first_url, nil), nil]],
        package: package_returning(first_url, '1.0.0', [required_question('Q1')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to include('Item `Q1` is required and enabled, but has no answer')
    end

    it 'keeps using the previous response while the Questionnaire is still in progress' do
      build_exchanges(
        [
          [request_for(first_url, nil, response_items: [answered('Q0')]),
           response_returning(first_url, nil, [required_question('Q1')])],
          [request_for(first_url, nil, response_items: [answered('Q1')]), nil]
        ],
        package: package_returning(first_url, nil, [required_question('Q0')])
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
