require_relative '../../update_test'

module DaVinciDTRTestKit
  class QuestionnaireResponseUpdateTest < Inferno::Test
    include DaVinciDTRTestKit::UpdateTest

    title 'Server is capable of updating a QuestionnaireResponse resource from QuestionnaireResponse update interaction'
    description 'A server SHALL support the QuestionnaireResponse update interaction'

    id :questionnaire_response_update
    input :update_questionnaire_resources

    def resource_type
      'QuestionnaireResponse'
    end

    run do
      perform_update_test(update_questionnaire_resources, resource_type)
    end
  end
end
