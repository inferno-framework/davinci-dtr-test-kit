module DaVinciDTRTestKit
    class DTRSmartAppSuite < Inferno::TestSuite
      id :dtr_smart_app
      title 'Da Vinci DTR Smart App Test Suite'
      description %(
        # Da Vinci DTR Smart App Test Suite

        This suite validates that a DTR Smart App can interact
        with a payer server and a light DTR EMR to complete
        questionnaires. Inferno will act as a payer server returning
        questionnaires in response to requests from the system under
        test and also as a light DTR EMR responding to requests for
        data.
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
  