require 'json' # TEMP
require 'sinatra/base' # TEMP

module DaVinciDTRTestKit
  module Endpoints
    module MockPayer
      class LightEHRSupportedPayerEndpoint < Sinatra::Base
        get '/supported-payers' do
          content_type :json
          status 200
          {
            payers: [
              { id: 'payer1', name: 'Payer One' },
              { id: 'payer2', name: 'Payer Two' }
            ]
          }.to_json
        end
      end
    end
  end
end
