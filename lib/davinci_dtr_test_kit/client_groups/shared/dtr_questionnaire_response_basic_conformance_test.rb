require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseBasicConformanceTest < Inferno::Test
    include URLs

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

      assert_valid_json(request.request_body)
      questionnaire_response = FHIR.from_contents(request.request_body)
      assert questionnaire_response.present?, 'Request does not contain a recognized FHIR object'
      assert_resource_type(:questionnaire_response, resource: questionnaire_response)

      assert_valid_resource(resource: questionnaire_response,
                            profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse|2.0.1')
    end
  end
end
