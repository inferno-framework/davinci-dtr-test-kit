require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseConformanceTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_questionnaire_response_conformance
    title 'QuestionnaireResponse is conformant'

    def profile_url
      config.options[:qr_profile_url]
    end

    run do
      skip_if questionnaire_response.nil?, 'Completed QuestionnaireResponse input was blank'
      verify_basic_conformance(questionnaire_response, profile_url)
    end
  end
end
