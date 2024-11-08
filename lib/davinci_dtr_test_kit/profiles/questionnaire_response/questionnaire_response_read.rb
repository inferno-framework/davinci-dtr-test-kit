require 'us_core_test_kit'

module DaVinciDTRTestKit
  class QuestionnaireResponseReadTest < Inferno::Test
    include USCoreTestKit::ReadTest

    title 'Server returns correct QuestionnaireResponse resource from QuestionnaireResponse read interaction'
    description 'A server SHALL support the QuestionnaireResponse read interaction'

    id :questionnaire_response_read

    def resource_type
      'QuestionnaireResponse'
    end

    def scratch_resources
      scratch[:questionnaire_response_resources] ||= {}
    end

    run do
      perform_read_test(all_scratch_resources)
    end
  end
end
