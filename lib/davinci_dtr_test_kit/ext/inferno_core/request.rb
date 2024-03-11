module Inferno
  module Entities
    class Request
      def self.to_hanami_response(request, response)
        response.status = request.status
        response.body = request.response_body
        request.response_headers.each do |header|
          response.headers[header.name] = header.value
        end

        response
      end

      def response_headers=(headers_hash)
        headers.concat(headers_hash.map { |key, value| Header.new(name: key.to_s, value:, type: 'response') })
      end
    end
  end
end
