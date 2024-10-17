require 'spec_helper'
require 'rack/test'
require 'inferno/apps/web/application'

module RequestHelpers
  include Rack::Test::Methods
  def app
    Inferno::Web.app
  end

  def parsed_body
    JSON.parse(last_response.body)
  end
end
