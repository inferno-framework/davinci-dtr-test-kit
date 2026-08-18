require_relative '../../../tags'
require_relative '../../validation_test'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class AdaptiveQuestionnaireResponseValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest
      include QuestionnaireOperationValidation

      ADAPTIVE_QUESTIONNAIRE_SEARCH_PROFILE =
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt-search|2.2.0'.freeze
      ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'.freeze

      id :dtr_v220_payer_adaptive_questionnaire_response_validation
      title 'Validate adaptive Questionnaires against the DTR AdaptiveQuestionnaire-Search profile'
      description %(
        This test validates Questionnaires responses are compliant with the DTR AdaptiveQuestionnaire-Search profile. 
        It will check that the Questionnaires returned from the $questionnaire-package operation are valid against the profile.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-23'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?, 'No $questionnaire-package requests were made.'

        successful_requests = requests.select { |request| [200, 201].include? request.response.status }

        skip_if successful_requests.blank?, 'No successful $questionnaire-package requests were made'

        questionnaires = requests.flat_map do |request|
          resource = FHIR.from_contents(request.response_body)
          bundles = extract_questionnaire_bundles(resource)
          next [] if bundles.blank?

          extract_questionnaires_from_bundles(bundles)
        end

        skip_if questionnaires.blank?, 'No Questionnaires were found.'

        adaptive_questionnaires = questionnaires.select do |questionnaire|
          questionnaire.extension&.any? do |extension|
            extension.url == ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL
          end
        end

        skip_if adaptive_questionnaires.blank?, 'No adaptive Questionnaires were found.'

        perform_response_validation_test(
          adaptive_questionnaires,
          :questionnaire,
          ADAPTIVE_QUESTIONNAIRE_SEARCH_PROFILE
        )
      end
    end
  end
end
