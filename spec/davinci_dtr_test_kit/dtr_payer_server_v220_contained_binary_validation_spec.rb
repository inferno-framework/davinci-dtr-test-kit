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

  def xhtml(content)
    "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{content}</div>"
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

  it 'accepts a non-empty XHTML Narrative fragment with permitted formatting' do
    xhtml_binary = binary(
      'application/xhtml+xml',
      xhtml('<p style="font-weight: bold">Instructions <a href="https://example.com">more</a></p><img src="#image"/>')
    )

    expect(validator.contained_binary_is_safe?(xhtml_binary)).to be(true)
  end

  it 'rejects a Binary with an unsupported content type' do
    image = binary('image/png', 'not an allowed page')

    expect(validator.contained_binary_is_safe?(image)).to be(false)
  end

  it 'rejects malformed XHTML and malformed base64 content' do
    malformed_xhtml = binary('application/xhtml+xml', '<div xmlns="http://www.w3.org/1999/xhtml"><p></div>')
    malformed_data = FHIR::Binary.new(contentType: 'application/xhtml+xml', data: 'not base64')

    expect(validator.contained_binary_is_safe?(malformed_xhtml)).to be(false)
    expect(validator.contained_binary_is_safe?(malformed_data)).to be(false)
  end

  it 'rejects documents instead of XHTML Narrative fragments' do
    html_document = binary('application/xhtml+xml', '<html><body><p>Instructions</p></body></html>')

    expect(validator.contained_binary_is_safe?(html_document)).to be(false)
  end

  it 'rejects an empty XHTML Narrative fragment' do
    empty_fragment = binary('application/xhtml+xml', xhtml('  '))

    expect(validator.contained_binary_is_safe?(empty_fragment)).to be(false)
  end

  it 'rejects the elements explicitly prohibited by FHIR Narrative rules' do
    prohibited_elements = %w[base body form frame frameset head iframe input link object script style]

    prohibited_elements.each do |element|
      xhtml_binary = binary('application/xhtml+xml', xhtml("<#{element}>Instructions</#{element}>"))

      expect(validator.contained_binary_is_safe?(xhtml_binary)).to be(false), element
    end
  end

  it 'rejects deprecated XHTML elements' do
    deprecated_elements = %w[basefont center dir font isindex menu s strike u]

    deprecated_elements.each do |element|
      xhtml_binary = binary('application/xhtml+xml', xhtml("<#{element}>Instructions</#{element}>"))

      expect(validator.contained_binary_is_safe?(xhtml_binary)).to be(false), element
    end
  end

  it 'rejects event attributes, xlink content, and executable URLs' do
    event = binary('application/xhtml+xml', xhtml('<p onclick="alert(1)">Text</p>'))
    xlink = binary(
      'application/xhtml+xml', xhtml('<a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#id">Text</a>')
    )
    xlink_element = binary(
      'application/xhtml+xml', xhtml('<xlink:custom xmlns:xlink="http://www.w3.org/1999/xlink">Text</xlink:custom>')
    )
    url = binary('application/xhtml+xml', xhtml('<a href="javascript:alert(1)">Text</a>'))

    expect(validator.contained_binary_is_safe?(event)).to be(false)
    expect(validator.contained_binary_is_safe?(xlink)).to be(false)
    expect(validator.contained_binary_is_safe?(xlink_element)).to be(false)
    expect(validator.contained_binary_is_safe?(url)).to be(false)
  end

  it 'only returns Binary resources contained in QuestionnaireResponses' do
    binary_resource = binary('application/pdf', '%PDF-1.7')
    questionnaire_response = questionnaire_response_with(binary_resource)

    expect(validator.contained_binaries([questionnaire_response])).to eq([binary_resource])
  end
end
