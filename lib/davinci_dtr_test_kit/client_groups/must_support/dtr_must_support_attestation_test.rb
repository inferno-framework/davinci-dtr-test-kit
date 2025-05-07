require 'securerandom'
require_relative '../../urls'
module DaVinciDTRTestKit
  class DTRMustSupportAttestationTest < Inferno::Test
    include URLs
    id :dtr_must_support_attest
    title 'Support for mustSupport Elements in Questionnaire (Attestation)'
    description %(
      The DTR client SHALL be able to handle all `mustSupport` elements defined in the Questionnaire profile.

      The tester attests that the client has:
      - Successfully requested, rendered, and completed each of the provided questionnaires.
      - Presented appropriate visual cues or guidance wherever `mustSupport` elements affect expected user actions.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@15', 'hl7.fhir.us.davinci-dtr_2.0.1@16',
                          'hl7.fhir.us.davinci-dtr_2.0.1@65', 'hl7.fhir.us.davinci-dtr_2.0.1@66',
                          'hl7.fhir.us.davinci-dtr_2.0.1@206'

    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the client application successfully handled all `mustSupport` elements
          defined in the [DTR Standard Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire|2.0.1)
          by, and therefore is capable of successfully handling all `mustSupport` elements defined in the
          [DTR Adaptive Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt|2.0.1):

          - Requesting, rendering, and completing each of the provided questionnaires.
          - Displaying appropriate visual cues or guidance where `mustSupport` elements impact expected user actions.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
