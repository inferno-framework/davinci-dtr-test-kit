require 'base64'
require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/contained_binary_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ContainedBinaryTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
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
        attr_accessor :mock_requests
      end

      id :dtr_v220_payer_contained_binary_spec

      def load_tagged_requests(*)
        requests.concat(self.class.mock_requests)
      end
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
  end

  def response_with(*binaries)
    questionnaire = FHIR::Questionnaire.new(id: 'questionnaire', status: 'draft')
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress', questionnaire: '#questionnaire', contained: [questionnaire, *binaries]
    )
    bundle = FHIR::Bundle.new(type: 'collection', entry: [FHIR::Bundle::Entry.new(resource: questionnaire_response)])
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)]
    ).to_json
  end

  def mock_questionnaire_package_response(*binaries)
    test_class.mock_requests = [
      Inferno::Entities::Request.new(
        verb: 'post', url: 'https://payer.example.com/Questionnaire/$questionnaire-package',
        direction: 'outgoing', status: 200, response_body: response_with(*binaries),
        test_session_id: test_session.id
      )
    ]
  end

  it 'passes when there is just a contained PDF Binary resource' do
    mock_questionnaire_package_response(pdf_binary)

    result = run(test_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes when there is just a contained XHTML Binary resource' do
    mock_questionnaire_package_response(xhtml_binary)

    result = run(test_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes when there are both contained PDF and XHTML Binary resources' do
    mock_questionnaire_package_response(pdf_binary, xhtml_binary)

    result = run(test_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when there is a contained Binary resource with an unsupported content type' do
    mock_questionnaire_package_response(unsupported_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Contained Binary resources must be PDFs or safe XHTML pages')
  end

  it 'fails when there are both supported and unsupported contained Binary resources' do
    mock_questionnaire_package_response(pdf_binary, xhtml_binary, unsupported_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Contained Binary resources must be PDFs or safe XHTML pages')
  end

  it 'fails when a contained XHTML Binary contains a script' do
    mock_questionnaire_package_response(script_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
  end

  it 'fails when a contained XHTML Binary contains an event handler' do
    mock_questionnaire_package_response(event_handler_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
  end

  it 'fails when a contained XHTML Binary contains a javascript URL' do
    mock_questionnaire_package_response(javascript_url_binary)

    result = run(test_class)

    expect(result.result).to eq('fail')
  end

  it 'skips when the response contains no Binary resources' do
    mock_questionnaire_package_response

    result = run(test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Binary resources were contained in QuestionnaireResponses')
  end

  it 'skips when no $questionnaire-package requests were made' do
    test_class.mock_requests = []

    result = run(test_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No $questionnaire-package requests were made')
  end
end
