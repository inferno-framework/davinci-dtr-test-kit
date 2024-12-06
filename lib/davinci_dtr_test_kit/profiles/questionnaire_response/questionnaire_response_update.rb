require_relative '../../update_test'

module DaVinciDTRTestKit
  class QuestionnaireResponseUpdateTest < Inferno::Test
    include DaVinciDTRTestKit::UpdateTest

    title 'Server is capable of updating a QuestionnaireResponse resource from QuestionnaireResponse update interaction'
    description 'A server SHALL support the QuestionnaireResponse update interaction'

    id :questionnaire_response_update
    input :update_questionnaire_resources,
          type: 'textarea',
          title: 'Update QuestionnaireResponse Resources',
          description:
          'Provide a list of QuestionnaireResponse resources to update. e.g., [json_resource_1, json_resource_2]',
          optional: true

    def resource_type
      'QuestionnaireResponse'
    end

    run do
      perform_update_test(update_questionnaire_resources, resource_type)
    end
  end
end
