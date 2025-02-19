module DaVinciDTRTestKit
  class QuestionnaireResponseReadTest < Inferno::Test
    include USCoreTestKit::ReadTest

    title 'Server returns correct QuestionnaireResponse resource from QuestionnaireResponse read interaction'
    description 'A server SHALL support the QuestionnaireResponse read interaction'
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@265'

    id :questionnaire_response_read

    def resource_type
      'QuestionnaireResponse'
    end

    def scratch_resources
      scratch[:questionnaire_responses] ||= {}
    end

    run do
      perform_read_test(all_scratch_resources)
    end
  end
end
