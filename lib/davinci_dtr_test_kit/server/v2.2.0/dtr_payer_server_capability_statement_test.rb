module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRPayerServerCapabilityStatementTest < Inferno::Test
      id :dtr_payer_server_v220_capability_statement_test

      title 'CapabilityStatement declares conformance to a DTR configuration'

      description %(
        The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#conformance-to-this-implementation-guide)
        systems to conform to at least one of its defined CapabilityStatements. This test retrieves
        the system CapabilityStatement and verifies that it declares conformance to a supported DTR configuration.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-1'

      SUPPORTED_DTR_CAPABILITY_STATEMENTS = [
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/light-dtr-ehr-311',
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/light-dtr-ehr-700',
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/full-dtr-ehr-311',
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/full-dtr-ehr-700',
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/smart-dtr-client',
        'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/dtr-payer-service'
      ].freeze

      run do
        fhir_get_capability_statement

        assert_response_status(200)
        assert_resource_type(:capability_statement)

        declared_capability_statement_urls = Array(resource.instantiates).map do |conformant|
          conformant.to_s.split('|').first
        end

        matching_capability_statements =
          declared_capability_statement_urls & SUPPORTED_DTR_CAPABILITY_STATEMENTS

        assert matching_capability_statements.present?,
               'CapabilityStatement does not declare conformance to a supported DTR ' \
               'CapabilityStatement. Expected one of: ' \
               "#{SUPPORTED_DTR_CAPABILITY_STATEMENTS.join(', ')}."
      end
    end
  end
end
