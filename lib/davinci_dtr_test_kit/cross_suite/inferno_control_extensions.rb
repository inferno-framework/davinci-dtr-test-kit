module DaVinciDTRTestKit
  # URLs of the extensions that control how Inferno's simulated payer builds responses from
  # response templates. Inferno removes them before responding. See
  # docs/Controlling-Simulated-Responses.md for what each one does.
  module InfernoControlExtensions
    EXTENSION_BASE_URL = 'https://inferno.healthit.gov/test-kits/davinci-dtr/StructureDefinition'.freeze

    INCLUSION_CRITERIA_URL = "#{EXTENSION_BASE_URL}/extension-inclusion-criteria".freeze
    REQUEST_RANGE_URL = "#{EXTENSION_BASE_URL}/extension-request-range".freeze
    INCLUDE_RESOURCE_URL = "#{EXTENSION_BASE_URL}/extension-include-resource".freeze
    INCLUDE_IN_PACKAGE_URL = "#{EXTENSION_BASE_URL}/extension-include-in-package".freeze
    INCLUDE_VALUE_SET_EXPANDED_URL = "#{EXTENSION_BASE_URL}/extension-include-value-set-expanded".freeze
    USE_NEXT_QUESTION_TEMPLATE_URL =
      "#{EXTENSION_BASE_URL}/extension-use-next-question-questionnaire-template".freeze

    # Earlier URLs for the same extensions, still accepted so that existing templates keep working.
    LEGACY_URLS = {
      INCLUSION_CRITERIA_URL => 'urn:inferno:dtr:inclusion-criteria',
      REQUEST_RANGE_URL => 'urn:inferno:dtr:request-range'
    }.freeze

    ALL_URLS = ([
      INCLUSION_CRITERIA_URL,
      REQUEST_RANGE_URL,
      INCLUDE_RESOURCE_URL,
      INCLUDE_IN_PACKAGE_URL,
      INCLUDE_VALUE_SET_EXPANDED_URL,
      USE_NEXT_QUESTION_TEMPLATE_URL
    ] + LEGACY_URLS.values).freeze

    def self.extension_matches?(extension, url)
      extension.url == url || (LEGACY_URLS.key?(url) && extension.url == LEGACY_URLS[url])
    end

    def self.find_extension(element, url)
      element.extension.find { |extension| extension_matches?(extension, url) }
    end
  end
end
