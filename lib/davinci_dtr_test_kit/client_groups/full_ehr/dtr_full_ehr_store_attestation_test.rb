require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStoreAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_store_attestation
    title 'Complete and Store the QuestionnaireResponse (Attestation)'
    description %(
      Attest that the questionnaire has been completed and the response has been persisted
      and can be exported as a FHIR QuestionnaireResponse instance.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that the questionnaire has been completed and stored within the EHR for future
          use and export as a FHIR QuestionnaireResponse instance.

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
