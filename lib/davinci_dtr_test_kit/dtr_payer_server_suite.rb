module DaVinciDTRTestKit
    class DTRPayerServerSuite < Inferno::TestSuite
      id :dtr_payer_server
      title 'Da Vinci DTR Payer Server Test Suite'
      description %(
        # Da Vinci DTR Payer Server Test Suite

        This suite validates that a payer server can act as a source
        of questionnaires for a DTR application to complete. Inferno
        will act as a DTR application requesting questionnaires from
        the system under test.
      )
  
      # These inputs will be available to all tests in this suite
      input :url,
            title: 'FHIR Server Base Url'
  
      input :credentials,
            title: 'OAuth Credentials',
            type: :oauth_credentials,
            optional: true
  
      # All FHIR requests in this suite will use this FHIR client
      fhir_client do
        url :url
        oauth_credentials :credentials
      end
  
      # All FHIR validation requsets will use this FHIR validator
      validator do
        url ENV.fetch('VALIDATOR_URL')
      end
    end
  end
  