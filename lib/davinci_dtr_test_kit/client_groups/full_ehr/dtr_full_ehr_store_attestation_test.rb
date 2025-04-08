require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStoreAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_store_attest
    title 'Complete and Store the QuestionnaireResponse (Attestation)'
    description %(
      Attest that the questionnaire has been completed and the response has been persisted
      and can be exported as a FHIR QuestionnaireResponse instance.
    )

    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: <<~MESSAGE
          I attest that questionnaires have been completed and stored within the EHR for future
          use and export as a FHIR QuestionnaireResponse instance.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        MESSAGE
      )
    end
  end
end
