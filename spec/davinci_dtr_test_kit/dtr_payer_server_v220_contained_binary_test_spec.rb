require 'base64'
require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/contained_binary_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ContainedBinaryTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:invalid_binary_message) do
    'Contained Binary resources must be PDFs or safe XHTML pages without active content or scripts.'
  end
  let(:invalid_json_message) { 'Invalid JSON. Response is not valid JSON' }
  let(:pdf_binary) do
    FHIR::Binary.new(contentType: 'application/pdf', data: Base64.strict_encode64('%PDF-1.7'))
  end
  let(:xhtml_binary) do
    FHIR::Binary.new(
      contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64('<html><body><p>Instructions</p></body></html>')
    )
  end
  let(:unsupported_binary) do
    FHIR::Binary.new(contentType: 'image/png', data: Base64.strict_encode64('image'))
  end
  let(:script_binary) do
    FHIR::Binary.new(
      contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64('<html><body><script>alert(1)</script></body></html>')
    )
  end
  let(:event_handler_binary) do
    FHIR::Binary.new(
      contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64('<html><body><p onclick="alert(1)">Text</p></body></html>')
    )
  end
  let(:javascript_url_binary) do
    FHIR::Binary.new(
      contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64('<html><body><a href="javascript:alert(1)">Text</a></body></html>')
    )
  end
  let(:test_class) do
    Class.new(described_class) do
      class << self
        attr_accessor :mock_requests_by_tag
      end

      id :dtr_v220_payer_contained_binary_spec

      def load_tagged_requests(*tags)
        tagged_requests = tags.flat_map { |tag| self.class.mock_requests_by_tag.fetch(tag, []) }
        requests.concat(tagged_requests)
        tagged_requests
      end
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
    test_class.mock_requests_by_tag = {}
  end

  def questionnaire_response_with(*binaries)
    questionnaire = FHIR::Questionnaire.new(id: 'questionnaire', status: 'draft')
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress', questionnaire: '#questionnaire', contained: [questionnaire, *binaries]
    )
  end

  def questionnaire_package_response_with(*binaries)
    questionnaire_package_response_with_questionnaire_responses(questionnaire_response_with(*binaries))
  end

  def questionnaire_package_response_with_questionnaire_responses(*questionnaire_responses)
    FHIR::Parameters.new(
      parameter: questionnaire_responses.map do |questionnaire_response|
        bundle = FHIR::Bundle.new(
          type: 'collection', entry: [FHIR::Bundle::Entry.new(resource: questionnaire_response)]
        )
        FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)
      end
    ).to_json
  end

  def next_question_response_with(*binaries)
    questionnaire_response = questionnaire_response_with(*binaries)
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'return', resource: questionnaire_response)]
    ).to_json
  end

  def direct_next_question_response_with(*binaries)
    questionnaire_response_with(*binaries).to_json
  end

  def mock_response(tag, body)
    operation = tag == DaVinciDTRTestKit::QUESTIONNAIRE_TAG ? '$questionnaire-package' : '$next-question'
    test_class.mock_requests_by_tag[tag] = [
      Inferno::Entities::Request.new(
        verb: 'post', url: "https://payer.example.com/Questionnaire/#{operation}",
        direction: 'outgoing', status: 200, response_body: body, test_session_id: test_session.id
      )
    ]
  end

  def mock_questionnaire_package_response(*binaries)
    mock_response(DaVinciDTRTestKit::QUESTIONNAIRE_TAG, questionnaire_package_response_with(*binaries))
  end

  def mock_next_question_response(*binaries)
    mock_response(DaVinciDTRTestKit::NEXT_TAG, next_question_response_with(*binaries))
  end

  def mock_direct_next_question_response(*binaries)
    mock_response(DaVinciDTRTestKit::NEXT_TAG, direct_next_question_response_with(*binaries))
  end

  shared_examples 'contained Binary validation' do
    it 'passes with a contained PDF Binary resource' do
      mock_operation_response.call(pdf_binary)

      result = run(test_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'passes with a contained XHTML Binary resource' do
      mock_operation_response.call(xhtml_binary)

      result = run(test_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'passes with both contained PDF and XHTML Binary resources' do
      mock_operation_response.call(pdf_binary, xhtml_binary)

      result = run(test_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails with a contained Binary resource that has an unsupported content type' do
      mock_operation_response.call(unsupported_binary)

      result = run(test_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(invalid_binary_message)
    end

    it 'fails with both supported and unsupported contained Binary resources' do
      mock_operation_response.call(pdf_binary, xhtml_binary, unsupported_binary)

      result = run(test_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(invalid_binary_message)
    end

    it 'fails when a contained XHTML Binary contains a script' do
      mock_operation_response.call(script_binary)

      result = run(test_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(invalid_binary_message)
    end

    it 'fails when a contained XHTML Binary contains an event handler' do
      mock_operation_response.call(event_handler_binary)

      result = run(test_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(invalid_binary_message)
    end

    it 'fails when a contained XHTML Binary contains a javascript URL' do
      mock_operation_response.call(javascript_url_binary)

      result = run(test_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(invalid_binary_message)
    end

    it 'skips when there are no contained Binary resources' do
      mock_operation_response.call

      result = run(test_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Binary resources were contained in QuestionnaireResponses')
    end
  end

  context 'with a $questionnaire-package response' do
    let(:mock_operation_response) { ->(*binaries) { mock_questionnaire_package_response(*binaries) } }

    it_behaves_like 'contained Binary validation'
  end

  context 'with a $next-question response' do
    let(:mock_operation_response) { ->(*binaries) { mock_next_question_response(*binaries) } }

    it_behaves_like 'contained Binary validation'
  end

  context 'with a direct QuestionnaireResponse from $next-question' do
    let(:mock_operation_response) { ->(*binaries) { mock_direct_next_question_response(*binaries) } }

    it_behaves_like 'contained Binary validation'
  end

  it 'passes when $questionnaire-package and $next-question both return safe Binary resources' do
    mock_questionnaire_package_response(pdf_binary)
    mock_next_question_response(xhtml_binary)

    result = run(test_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when $questionnaire-package is valid and $next-question contains an invalid Binary resource' do
    mock_questionnaire_package_response(pdf_binary)
    mock_next_question_response(unsupported_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(invalid_binary_message)
  end

  it 'fails when $questionnaire-package contains an invalid Binary resource and $next-question is valid' do
    mock_questionnaire_package_response(unsupported_binary)
    mock_next_question_response(xhtml_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(invalid_binary_message)
  end

  it 'skips a $questionnaire-package packagebundle output that is not a Bundle' do
    response_body = FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: questionnaire_response_with(pdf_binary))
      ]
    ).to_json
    mock_response(DaVinciDTRTestKit::QUESTIONNAIRE_TAG, response_body)

    result = run(test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Binary resources were contained in QuestionnaireResponses')
  end

  it 'fails with the expected message when a $questionnaire-package response is not valid JSON' do
    mock_response(DaVinciDTRTestKit::QUESTIONNAIRE_TAG, '')

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(invalid_json_message)
  end

  it 'fails with the expected message when a $next-question response is not valid JSON' do
    mock_response(DaVinciDTRTestKit::NEXT_TAG, '')

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(invalid_json_message)
  end

  it 'skips when no $questionnaire-package or $next-question requests were made' do
    result = run(test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No $questionnaire-package or $next-question requests were made')
  end
end
