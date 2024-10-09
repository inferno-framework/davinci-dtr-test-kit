require_relative '../../urls'
require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseBasicConformanceTest < Inferno::Test
    include URLs
    include DTRQuestionnaireResponseValidation

    id :dtr_questionnaire_response_basic_conformance
    title 'QuestionnaireResponse is conformant'
    description %(
      This test validates the conformance of QuestionnaireResponse representing the
      completed questionnaire. It verifies that the QuestionnaireResponse conforms
      to the DTR Questionnaire Response resource profile.
    )

    run do
      assert request.url == questionnaire_response_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{questionnaire_response_url}"

      verify_basic_conformance(request.request_body)
    end
  end
end
