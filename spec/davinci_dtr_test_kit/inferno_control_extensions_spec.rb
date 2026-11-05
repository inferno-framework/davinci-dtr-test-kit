require 'davinci_dtr_test_kit/cross_suite/inferno_control_extensions'

RSpec.describe DaVinciDTRTestKit::InfernoControlExtensions do
  def element_with(url)
    FHIR::Questionnaire::Item.new(linkId: 'Q1', extension: [FHIR::Extension.new(url:, valueString: '1')])
  end

  describe '.find_extension' do
    it 'finds an extension by its current url' do
      element = element_with(described_class::REQUEST_RANGE_URL)

      expect(described_class.find_extension(element, described_class::REQUEST_RANGE_URL)).to be_present
    end

    it 'finds an extension by its legacy url' do
      described_class::LEGACY_URLS.each do |url, legacy_url|
        expect(described_class.find_extension(element_with(legacy_url), url)).to be_present
      end
    end

    it 'does not match a different extension' do
      element = element_with(described_class::REQUEST_RANGE_URL)

      expect(described_class.find_extension(element, described_class::INCLUSION_CRITERIA_URL)).to be_nil
    end
  end

  it 'lists the legacy urls among those removed before responding' do
    expect(described_class::ALL_URLS).to include(*described_class::LEGACY_URLS.values)
  end
end
