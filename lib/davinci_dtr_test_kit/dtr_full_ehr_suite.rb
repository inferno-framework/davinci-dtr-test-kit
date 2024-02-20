module DaVinciDTRTestKit
    class DTRFullEHRSuite < Inferno::TestSuite
      id :dtr_full_ehr
      title 'Da Vinci DTR Full EHR Test Suite'
      description %(
        # Da Vinci DTR Full EHR Test Suite

        This suite validates that an EHR or other application can act
        as a full DTR application requesting questionnaires from a 
        payer server and using local data to complete and store them.
        Inferno will act as payer server returning questionnaires
        in response to queries from the system under test and validating
        that they can be completed as expected.
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
  