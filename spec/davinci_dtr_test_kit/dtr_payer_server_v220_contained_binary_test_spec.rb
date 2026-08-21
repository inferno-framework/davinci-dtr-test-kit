require 'base64'
require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/contained_binary_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ContainedBinaryTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:test_requests) { [] }
  let(:invalid_binary_message) do
    'Contained Binary resources must be PDFs or safe XHTML fragments. See Messages for details.'
  end
  let(:pdf_binary) do
    FHIR::Binary.new(id: 'pdf-binary', contentType: 'application/pdf', data: Base64.strict_encode64('%PDF-1.7'))
  end
  let(:xhtml_binary) do
    FHIR::Binary.new(
      id: 'xhtml-binary', contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64(narrative_xhtml('<p>Instructions</p>'))
    )
  end
  let(:unsupported_binary) do
    FHIR::Binary.new(id: 'unsupported-binary', contentType: 'image/png', data: Base64.strict_encode64('image'))
  end
  let(:script_binary) do
    FHIR::Binary.new(
      id: 'script-binary', contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64(narrative_xhtml('<script>alert(1)</script>'))
    )
  end
  let(:event_handler_binary) do
    FHIR::Binary.new(
      id: 'event-handler-binary', contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64(narrative_xhtml('<p onclick="alert(1)">Text</p>'))
    )
  end
  let(:javascript_url_binary) do
    FHIR::Binary.new(
      id: 'javascript-url-binary', contentType: 'application/xhtml+xml',
      data: Base64.strict_encode64(narrative_xhtml('<a href="javascript:alert(1)">Text</a>'))
    )
  end

  before do
    allow_any_instance_of(described_class).to receive(:requests).and_return(test_requests)
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def questionnaire_response_with(*binaries)
    questionnaire = FHIR::Questionnaire.new(id: 'questionnaire', status: 'draft')
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress', questionnaire: '#questionnaire', contained: [questionnaire, *binaries]
    )
  end

  def narrative_xhtml(content)
    "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{content}</div>"
  end

  def mock_response(*binaries)
    test_requests << repo_create(:request, response_body: questionnaire_response_with(*binaries).to_json)
  end

  it 'passes with a contained PDF Binary resource' do
    mock_response(pdf_binary)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes with a contained XHTML Binary resource' do
    mock_response(xhtml_binary)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes with both contained PDF and XHTML Binary resources' do
    mock_response(pdf_binary, xhtml_binary)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'reports the Binary identifier and request index for an unsupported content type' do
    mock_response(pdf_binary)
    mock_response(unsupported_binary)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(invalid_binary_message)
    expect(result.result_message).to include('Request 2:')
    expect(result_messages.map(&:message).join)
      .to include('(Request 2) Binary `unsupported-binary` is not a PDF or safe XHTML fragment.')
  end

  it 'fails when a contained XHTML Binary contains a script' do
    mock_response(script_binary)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(invalid_binary_message)
    expect(result_messages.map(&:message).join)
      .to include('(Request 1) Binary `script-binary` is not a PDF or safe XHTML fragment.')
  end

  it 'fails when a contained XHTML Binary contains an event handler' do
    mock_response(event_handler_binary)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(invalid_binary_message)
    expect(result_messages.map(&:message).join)
      .to include('(Request 1) Binary `event-handler-binary` is not a PDF or safe XHTML fragment.')
  end

  it 'fails when a contained XHTML Binary contains a javascript URL' do
    mock_response(javascript_url_binary)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(invalid_binary_message)
    expect(result_messages.map(&:message).join)
      .to include('(Request 1) Binary `javascript-url-binary` is not a PDF or safe XHTML fragment.')
  end

  it 'omits when no responses contain Binary resources' do
    mock_response

    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to eq('No Binary resources were contained in QuestionnaireResponses')
  end

  it 'omits when no $questionnaire-package or $next-question requests were made' do
    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to eq('No $questionnaire-package or $next-question requests were made')
  end
end
