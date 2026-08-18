require 'base64'
require 'nokogiri'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module ContainedBinaryValidation
      PDF_CONTENT_TYPE = 'application/pdf'.freeze
      XHTML_CONTENT_TYPE = 'application/xhtml+xml'.freeze

      # FHIR R4 limits narrative XHTML to basic formatting elements and attributes
      # and prohibits active content. These lists enforce that rule by rejecting
      # elements and URL schemes that can execute content.
      # https://hl7.org/fhir/R4/narrative.html#xhtml
      # https://hl7.org/fhir/R4/security.html#narrative
      ACTIVE_CONTENT_ELEMENTS = %w[applet base embed form frame frameset iframe input object script style].freeze
      EXECUTABLE_URL_SCHEMES = %w[javascript vbscript].freeze

      def contained_binaries(questionnaire_responses)
        questionnaire_responses.flat_map do |questionnaire_response|
          questionnaire_response.contained&.grep(FHIR::Binary) || []
        end
      end

      def contained_binary_is_safe?(binary)
        return true if binary.contentType == PDF_CONTENT_TYPE
        return false unless binary.contentType == XHTML_CONTENT_TYPE

        safe_xhtml?(Base64.strict_decode64(binary.data.to_s))
      rescue ArgumentError
        false
      end

      def safe_xhtml?(xhtml)
        # Strict parsing rejects malformed XHTML. `nonet` prevents XML from
        # loading any network resources while it is being parsed.
        document = Nokogiri::XML::Document.parse(xhtml) { |config| config.strict.nonet }
        return false unless document.root&.name == 'html'
        return false unless document.errors.empty?

        # `//*` selects every element in the XHTML document so each can be
        # checked for executable content and attributes.
        document.xpath('//*').all? { |element| safe_xhtml_element?(element) }
      rescue Nokogiri::XML::SyntaxError
        false
      end

      private

      def safe_xhtml_element?(element)
        return false if ACTIVE_CONTENT_ELEMENTS.include?(element.name.downcase)

        element.attribute_nodes.none? { |attribute| unsafe_xhtml_attribute?(attribute) }
      end

      def unsafe_xhtml_attribute?(attribute)
        # In XHTML, event handlers are attributes beginning with `on`, such as
        # `onclick`. They run JavaScript when the corresponding browser event occurs.
        return true if attribute.name.match?(/\Aon/i)

        # `href` and `src` are the XHTML attributes that direct a browser to
        # navigate to or load a URL. Other attributes cannot invoke a URL scheme.
        return false unless %w[href src].include?(attribute.name.downcase)

        # `javascript:` and `vbscript:` URLs execute code when followed instead
        # of loading a document or image.
        EXECUTABLE_URL_SCHEMES.include?(url_scheme(attribute.value))
      end

      def url_scheme(url)
        url.to_s.strip.partition(':').first.downcase
      end
    end
  end
end
