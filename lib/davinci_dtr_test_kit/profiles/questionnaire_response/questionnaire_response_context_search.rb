module DaVinciDTRTestKit
  class QuestionnaireResponseContextSearchTest < Inferno::Test
    include USCoreTestKit::SearchTest

    title 'Server returns valid results for QuestionnaireResponse search by context'
    description %(
A server SHALL support searching by
context on the QuestionnaireResponse resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@268',
                          'hl7.fhir.us.davinci-dtr_2.0.1@269'

    id :questionnaire_response_context_search

    def self.properties
      @properties ||= USCoreTestKit::SearchTestProperties.new(
        resource_type: 'QuestionnaireResponse',
        search_param_names: ['context']
      )
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:questionnaire_responses] ||= {}
    end

    run do
      run_search_test
    end
  end
end
