require_relative '../../create_test'

module DaVinciDTRTestKit
  class QuestionnaireResponseCreateTest < Inferno::Test
    include DaVinciDTRTestKit::CreateTest

    title 'Server is capable of creating a QuestionnaireResponse resource from QuestionnaireResponse create interaction'
    description 'A sever SHALL support the QuestionnaireResponse create interaction'

    id :questionnaire_response_create
    input :create_questionnaire_resources

    def resource_type
      'QuestionnaireResponse'
    end

    run do
      perform_create_test(create_questionnaire_resources, resource_type)
    end
  end
end
