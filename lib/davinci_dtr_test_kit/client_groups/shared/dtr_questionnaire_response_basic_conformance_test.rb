require_relative '../../urls'
require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseBasicConformanceTest < Inferno::Test
    include URLs
    include DTRQuestionnaireResponseValidation

    id :dtr_questionnaire_response_basic_conformance
    title 'QuestionnaireResponse is conformant'
    description %(
      This test validates the conformance of a `QuestionnaireResponse` representing a completed questionnaire.
      It ensures that the `QuestionnaireResponse` adheres to the appropriate profile based on its type:

      - **Static QuestionnaireResponse:** Must conform to the [DTR Questionnaire Response](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-dtr-questionnaireresponse.html) profile.
      - **Adaptive QuestionnaireResponse:** Must conform to the [Adaptive Questionnaire Response](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt) profile.
    )

    def profile_url
      config.options[:qr_profile_url]
    end

    run do
      assert request.url == questionnaire_response_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{questionnaire_response_url}"

      verify_basic_conformance(request.request_body, profile_url)
    end
  end
end
