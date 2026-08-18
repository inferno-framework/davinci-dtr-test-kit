require 'base64'
require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/contained_binary_validation'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ContainedBinaryValidation do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:validator) { validator_class.new }

  let(:validator_class) do
    Class.new do
      include DaVinciDTRTestKit::DTRPayerServerV220::ContainedBinaryValidation
    end
  end

  def binary(content_type, content)
    FHIR::Binary.new(contentType: content_type, data: Base64.strict_encode64(content))
  end

  def questionnaire_response_with(*binaries)
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      contained: [FHIR::Questionnaire.new(id: 'questionnaire', status: 'draft'), *binaries]
    )
  end

  it 'accepts contained PDF Binary resources' do
    pdf = binary('application/pdf', '%PDF-1.7')

    expect(validator.contained_binary_is_safe?(pdf)).to be(true)
  end

  it 'accepts well-formed XHTML without active content' do
    xhtml = binary('application/xhtml+xml', '<html><body><p>Instructions</p></body></html>')

    expect(validator.contained_binary_is_safe?(xhtml)).to be(true)
  end

  it 'rejects a Binary with an unsupported content type' do
    image = binary('image/png', 'not an allowed page')

    expect(validator.contained_binary_is_safe?(image)).to be(false)
  end

  it 'rejects malformed XHTML and malformed base64 content' do
    malformed_xhtml = binary('application/xhtml+xml', '<html><body><p></body></html>')
    malformed_data = FHIR::Binary.new(contentType: 'application/xhtml+xml', data: 'not base64')

    expect(validator.contained_binary_is_safe?(malformed_xhtml)).to be(false)
    expect(validator.contained_binary_is_safe?(malformed_data)).to be(false)
  end

  it 'rejects XHTML with scripts, event handlers, or javascript URLs' do
    script = binary('application/xhtml+xml', '<html><body><script>alert(1)</script></body></html>')
    event = binary('application/xhtml+xml', '<html><body><p onclick="alert(1)">Text</p></body></html>')
    url = binary('application/xhtml+xml', '<html><body><a href="javascript:alert(1)">Text</a></body></html>')
    expect(validator.contained_binary_is_safe?(script)).to be(false)
    expect(validator.contained_binary_is_safe?(event)).to be(false)
    expect(validator.contained_binary_is_safe?(url)).to be(false)
  end

  it 'only returns Binary resources contained in QuestionnaireResponses' do
    binary_resource = binary('application/pdf', '%PDF-1.7')
    questionnaire_response = questionnaire_response_with(binary_resource)

    expect(validator.contained_binaries([questionnaire_response])).to eq([binary_resource])
  end
end
