module DaVinciDTRTestKit
  module CORS
    PRE_FLIGHT_HANDLER = proc do
      [
        200,
        {
          'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
        },
        ['']
      ]
    end

    def allow_cors(*paths)
      paths.each do |path|
        route(:options, path, PRE_FLIGHT_HANDLER)
      end
    end
  end
end
