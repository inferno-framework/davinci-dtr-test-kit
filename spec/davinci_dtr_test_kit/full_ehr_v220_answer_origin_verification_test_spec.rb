require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/answer_origin_verification_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220AnswerOriginVerificationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  let(:information_origin_url) { 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin' }

  # Inferno's answer origin Questionnaire, as the client returns it contained in the QuestionnaireResponse
  let(:questionnaire) do
    template_path = File.join('lib', 'davinci_dtr_test_kit', 'full_ehr', 'fixtures', 'answer_origin',
                              'answer_origin_adaptive_next_question_template.json')
    JSON.parse(File.read(template_path))
  end

  let(:correct_questionnaire_response) do
    questionnaire_response(last_name: answer('Smith', 'auto-client'),
                           preferred_first_name: answer('Jojo', 'override'),
                           new_information: answer('Allergic to peanuts', 'manual'))
  end

  # Results returned directly by `run` don't carry their messages, so reload them from the session.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  # By default, answers the user entered ('manual' / 'override') name the user as their author, as
  # spec-137 requires. Pass `author: false` to leave the author out, or a nil source for no origin at all.
  def answer(value, source, author: true)
    answer = { valueString: value }
    return answer if source.nil?

    origin_parts = [{ url: 'source', valueCode: source }]
    if author && ['manual', 'override'].include?(source)
      origin_parts << { url: 'author',
                        extension: [{ url: 'practitioner', valueReference: { reference: 'Practitioner/pra1234' } }] }
    end
    answer[:extension] = [{ url: information_origin_url, extension: origin_parts }]
    answer
  end

  # Pass nil for a question to leave it unanswered.
  def questionnaire_response(last_name:, preferred_first_name:, new_information:)
    items = []
    items << { linkId: 'last-name-do-not-change', answer: [last_name] } unless last_name.nil?
    items << { linkId: 'preferred-first-name-update', answer: [preferred_first_name] } unless preferred_first_name.nil?
    items << { linkId: 'new-information-add', answer: [new_information] } unless new_information.nil?
    { resourceType: 'QuestionnaireResponse', status: 'in-progress', contained: [questionnaire], item: items }
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

  it 'passes when Last Name is auto-client, Preferred First Name is override, and New Information is manual' do
    create_nq_request(correct_questionnaire_response)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'accepts a request with the QuestionnaireResponse wrapped in Parameters' do
    parameters = {
      resourceType: 'Parameters',
      parameter: [{ name: 'questionnaire-response', resource: correct_questionnaire_response }]
    }
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
      test_session_id: test_session.id,
      result:,
      request_body: parameters.to_json,
      response_body: correct_questionnaire_response.merge(status: 'completed').to_json,
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
    create_nq_request(correct_questionnaire_response, response_status: 'in-progress')

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No $next-question request resulted in a completed QuestionnaireResponse')
  end

  describe 'when the completing request body is not usable' do
    # Inferno marked the response `completed`, but the client's request body is replaced with `request_body`.
    def create_completed_request_with_body(request_body)
      repo_create(
        :request,
        direction: 'incoming',
        url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
        test_session_id: test_session.id,
        result:,
        request_body:,
        response_body: correct_questionnaire_response.merge(status: 'completed').to_json,
        tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG],
        status: 200
      )
    end

    it 'fails when the body is empty' do
      create_completed_request_with_body('')

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('The completing $next-question request has an empty body.')
    end

    it 'fails when the body is not valid JSON' do
      create_completed_request_with_body('not json')

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(result.result_message)
        .to eq('The completing $next-question request does not contain a valid QuestionnaireResponse.')
    end

    it 'fails when the body is not a QuestionnaireResponse' do
      create_completed_request_with_body({ resourceType: 'OperationOutcome', issue: [] }.to_json)

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(result.result_message)
        .to eq('The completing $next-question request does not contain a valid QuestionnaireResponse.')
    end
  end

  it 'checks the answers from the last completed request, ignoring earlier in-progress requests' do
    earlier = questionnaire_response(last_name: answer('Smith', 'auto-client'),
                                     preferred_first_name: answer('Jo', 'auto-client'),
                                     new_information: nil)
    create_nq_request(earlier, response_status: 'in-progress')
    create_nq_request(correct_questionnaire_response)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when Last Name was changed' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smyth', 'override'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: answer('Allergic to peanuts', 'manual'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_including("The answer to `Last Name (don't change!)` has information-origin source `override`, " \
                         'but it should be `auto-client`')
    )
  end

  it 'fails, with a hint about the Patient, when Last Name had to be typed in' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'manual'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: answer('Allergic to peanuts', 'manual'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_including('make sure the Patient has a recorded last name'))
  end

  it 'fails when Preferred First Name was left unchanged' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jo', 'auto-client'),
                             new_information: answer('Allergic to peanuts', 'manual'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_including('The answer to `Preferred First Name (update)` has information-origin source `auto-client`, ' \
                         'but it should be `override`')
    )
  end

  it 'fails when New Information is not manual' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: answer('Allergic to peanuts', 'auto-client'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_including('The answer to `New Information (add details)` has information-origin source ' \
                         '`auto-client`, but it should be `manual`')
    )
  end

  it 'fails when an answer is missing the information-origin source' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: answer('Allergic to peanuts', nil))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_including('The answer to `New Information (add details)` is missing an information-origin ' \
                         'extension with a `source`')
    )
  end

  it 'fails when a question was not answered' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: nil)
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'No answer to `New Information (add details)` (linkId `new-information-add`).'
    )
  end

  it 'fails when the changed Preferred First Name has no author' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jojo', 'override', author: false),
                             new_information: answer('Allergic to peanuts', 'manual'))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'The answer to `Preferred First Name (update)` has no information-origin `author` with a `practitioner` ' \
      'reference identifying the user who entered it.'
    )
  end

  it 'fails when the typed-in New Information has no author' do
    create_nq_request(
      questionnaire_response(last_name: answer('Smith', 'auto-client'),
                             preferred_first_name: answer('Jojo', 'override'),
                             new_information: answer('Allergic to peanuts', 'manual', author: false))
    )

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_including('The answer to `New Information (add details)` has no information-origin `author`')
    )
  end

  it 'finds the questions even when the client nests them inside another item' do
    wrapper_item = { linkId: 'wrapper', item: correct_questionnaire_response[:item] }
    nested = correct_questionnaire_response.merge(item: [wrapper_item])
    create_nq_request(nested)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'only considers requests tagged for the configured workflow' do
    scoped_test_class = Class.new(described_class) do
      id :scoped_answer_origin_verification_spec_test
      config options: { dtr_workflow_tag: 'answer_origin' }
    end
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    create_nq_request(correct_questionnaire_response, tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'other_workflow'])

    result = run(scoped_test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('A $next-question request must be made prior to running this test.')
  end
end
