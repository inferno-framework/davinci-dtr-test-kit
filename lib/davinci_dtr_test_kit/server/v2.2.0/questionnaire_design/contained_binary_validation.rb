require 'base64'
require 'nokogiri'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module ContainedBinaryValidation
      PDF_CONTENT_TYPE = 'application/pdf'.freeze
      XHTML_CONTENT_TYPE = 'application/xhtml+xml'.freeze
      XHTML_NAMESPACE = 'http://www.w3.org/1999/xhtml'.freeze

      # TODO: Review the FHIR-referenced HTML 4.0 chapters in detail and determine
      # whether this validator needs additional allowed-element or allowed-attribute handling.
      #
      # This validator interprets Binary XHTML according to the FHIR R4 Narrative
      # fragment rules. It enforces the explicitly prohibited elements and
      # attributes, but does not yet attempt a comprehensive HTML allowlist.
      # https://hl7.org/fhir/R4/narrative.html#security
      #
      # "The XHTML content SHALL NOT contain a head, a body element,
      # external stylesheet references, deprecated elements, scripts,
      # forms, base/link/xlink, frames, iframes, objects or
      # event related attributes (e.g. onClick)."
      PROHIBITED_ELEMENTS = %w[
        base body form frame frameset head iframe input link object script style
      ].freeze
      # HTML 4.0 deprecated elements: https://www.w3.org/TR/REC-html40-971218/appendix/changes.html#h-A.1.2
      DEPRECATED_ELEMENTS = %w[applet basefont center dir font isindex menu s strike u].freeze
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
        document = parse_xhtml(xhtml)

        narrative_fragment?(document) &&
          document.errors.empty? &&
          narrative_has_content?(document) &&
          document_has_no_unsafe_content?(document)
      rescue Nokogiri::XML::SyntaxError
        false
      end

      private

      def parse_xhtml(xhtml)
        # Strict parsing rejects malformed XHTML. `nonet` prevents XML from
        # loading any network resources while it is being parsed.
        Nokogiri::XML::Document.parse(xhtml) { |config| config.strict.nonet }
      end

      def document_has_no_unsafe_content?(document)
        # Inspect every nested XHTML element, including elements in the default
        # XHTML namespace which a non-namespaced XPath would not reliably select.
        document.root.traverse do |node|
          return false if node.element? && unsafe_xhtml_element?(node)
        end

        true
      end

      def narrative_fragment?(document)
        # FHIR Narrative XHTML is represented as a div fragment in the XHTML namespace,
        # rather than as a complete HTML document.
        document.root&.name == 'div' && document.root.namespace&.href == XHTML_NAMESPACE
      end

      def narrative_has_content?(document)
        # FHIR Narrative requires non-whitespace text or an image in the div fragment.
        !document.root.text.strip.empty? ||
          !document.root.at_xpath('.//xhtml:img', xhtml: XHTML_NAMESPACE).nil?
      end

      def unsafe_xhtml_element?(element)
        prohibited_element?(element) ||
          deprecated_element?(element) ||
          xlink_node?(element) ||
          element.attribute_nodes.any? { |attribute| unsafe_xhtml_attribute?(attribute) }
      end

      def prohibited_element?(element)
        PROHIBITED_ELEMENTS.include?(element.name.downcase)
      end

      def deprecated_element?(element)
        DEPRECATED_ELEMENTS.include?(element.name.downcase)
      end

      def xlink_node?(node)
        # xlink is an XML namespace, so it can qualify either an element or an
        # attribute (for example, xlink:href) rather than appearing as an HTML element.
        node.namespace&.prefix == 'xlink'
      end

      def unsafe_xhtml_attribute?(attribute)
        # In XHTML, event handlers are attributes beginning with `on`, such as
        # `onclick`. They run JavaScript when the corresponding browser event occurs.
        return true if attribute.name.match?(/\Aon/i)

        return true if xlink_node?(attribute)

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
