require_relative '../../create_test'

module DaVinciDTRTestKit
  class QuestionnaireResponseCreateTest < Inferno::Test
    include DaVinciDTRTestKit::CreateTest

    title 'Server is capable of creating a QuestionnaireResponse resource from QuestionnaireResponse create interaction'
    description 'A sever SHALL support the QuestionnaireResponse create interaction'

    id :questionnaire_response_create
    input :create_questionnaire_resources,
          type: 'textarea',
          title: 'Create QuestionnaireResponse Resources',
          description:
          'Provide a list of QuestionnaireResponse resources to create. e.g., [json_resource_1, json_resource_2]',
          optional: true

    def resource_type
      'QuestionnaireResponse'
    end

    run do
      perform_create_test(create_questionnaire_resources, resource_type)
    end
  end
end
