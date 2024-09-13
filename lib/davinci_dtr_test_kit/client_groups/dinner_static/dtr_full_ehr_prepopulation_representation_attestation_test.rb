require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerPrepopulationRepresentationAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_dinner_static_prepopulation_representation_attestation
    title 'Verify the QuestionnaireResponse representation of the item data sources (Attestation)'
    description %(
      Attest that the QuestionnaireResponse representation of the stored answers includes the required
      source indicators, including `auto`, `override`, and `manual`.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that the QuestionnaireResponse representation of the stored answers includes the
          [orgin extension with source details](https://build.fhir.org/ig/HL7/davinci-dtr/StructureDefinition-information-origin.html),
          including on the following fields entered during the tests:
          - PBD.1 (Last Name): `auto`
          - PBD.2 (First Name): `override`
          - 3.1 (dinner choice): `manual`

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
