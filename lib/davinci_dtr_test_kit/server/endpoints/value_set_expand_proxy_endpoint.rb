require_relative 'payer_proxy_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class ValueSetExpandProxyEndpoint < PayerProxyEndpoint
      def outgoing_request_tags
        [VALUE_SET_EXPAND_TAG]
      end

      def payer_path
        '/ValueSet/$expand'
      end
    end
  end
end
