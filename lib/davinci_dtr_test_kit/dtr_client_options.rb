# frozen_string_literal: true

require 'smart_app_launch_test_kit'
require 'udap_security_test_kit'

module DaVinciDTRTestKit
  module DTRClientOptions
    SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC =
      SMARTAppLaunch::SMARTClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
    UDAP_CLIENT_CREDENTIALS =
      UDAPSecurityTestKit::UDAPClientOptions::UDAP_CLIENT_CREDENTIALS
  end
end
