require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseConformanceTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_qr_conformance
    title 'QuestionnaireResponse is conformant'
    description %(
      Verify that the provided QuestionnaireResponse is conformant to the [DTR
      QuestionnaireResponse](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-dtr-questionnaireresponse.html)
      profile.
    )

    def profile_url
      config.options[:qr_profile_url]
    end

    run do
      skip_if questionnaire_response.nil?, 'Completed QuestionnaireResponse input was blank'
      verify_basic_conformance(questionnaire_response, profile_url)
    end
  end
end
