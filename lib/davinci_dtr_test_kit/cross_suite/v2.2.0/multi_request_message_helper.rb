module DaVinciDTRTestKit
  module MultiRequestMessageHelper
    def request_prefix(request_index)
      "(Request #{request_index + 1}) "
    end

    def add_request_message(type, message, request_index)
      add_message(type, "#{request_prefix(request_index)}#{message}")
    end

    def parse_fhir_request_entity(body, entity, request_index)
      FHIR.from_contents(body)
    rescue JSON::ParserError
      add_request_message('error', "#{entity} contains invalid JSON.", request_index)
      nil
    end

    def requests_with_errors_prefix
      request_numbers = error_request_numbers
      return '' if request_numbers.empty?

      noun = request_numbers.size == 1 ? 'Request' : 'Requests'
      "#{noun} #{request_numbers.to_sentence}: "
    end

    private

    def error_request_numbers
      messages
        .select { |m| m[:type] == 'error' }
        .filter_map { |m| m[:message].match(/\A\(Request (\d+)\)/) { |md| md[1].to_i } } # md[1] = first capture group
        .sort.uniq
    end
  end
end
