require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRDinnerStaticQuestionnaireResponseConformanceTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_dinner_static_questionnaire_response_conformance
    title 'QuestionnaireResponse is conformant'

    run do
      skip_if questionnaire_response.nil?, 'Completed QuestionnaireResponse input was blank'
      verify_basic_conformance(questionnaire_response)
    end
  end
end
