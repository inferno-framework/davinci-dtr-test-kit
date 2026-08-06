require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class CQLLibraryValidationTest < Inferno::Test
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_cql_library_validation

      title 'CQL Library inclusion'
      description %(
        Inferno will verify that the payer server's response to the
        questionnaire-package operation includes all CQL Libraries referenced in
        the returned Questionnaires.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-87',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-95',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-98',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-99',
                            'hl7.fhir.us.davinci-dtr_2.2.0@oper-13',
                            'hl7.fhir.us.davinci-dtr_2.2.0@oper-16'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        successful_requests = requests.select { |request| [200, 201].include? request.response[:status] }

        skip_if successful_requests.blank?, 'No successful $questionnaire-package requests were made'

        library_count = 0

        successful_requests.each_with_index do |request, index|
          next unless [200, 201].include? request.response[:status]

          JSON.parse(request.response_body)

          resource = FHIR.from_contents(request.response_body)

          next if resource.nil?

          questionnaire_bundles = extract_questionnaire_bundles(resource)
          libraries = extract_libraries_from_bundles(questionnaire_bundles)

          next if libraries.blank?

          check_libraries(resource, index)

          library_count += libraries.length
        rescue JSON::ParserError
          next
        end

        assert_no_error_messages('Not all responses contained all necessary valid CQL Libraries.')

        omit_if library_count.zero?, 'No CQL libraries were found.'
      end
    end
  end
end
