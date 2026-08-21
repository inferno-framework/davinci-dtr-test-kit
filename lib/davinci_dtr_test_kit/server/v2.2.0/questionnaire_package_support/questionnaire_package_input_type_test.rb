require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePackageInputTypeTest < Inferno::Test
      id :dtr_v220_payer_questionnaire_package_input_type

      title 'Verify that all $questionnaire-package input types have been provided'
      description <<~DESCRIPTION
        This test verifies that the user has supplied inputs which contain each
        of the available input types for the $questionnaire-package operation:
        * canonicals specifying the URL and, (optionally) the version of the
          Questionnaire(s) to retrieve
        * A CRD/PAS context ID
        * One or more Request or Encounter resources

        Each input type must be provided in a set of paramaters without the
        others in order to verify the server's support for each input type.
      DESCRIPTION

      simulation_verification

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        parameters_list =
          requests.map do |request|
            JSON.parse(request.request_body)

            FHIR.from_contents(request.request_body)
          rescue JSON::ParserError
            nil
          end.compact

        skip_if parameters_list.blank?, 'No valid request bodies were provided.'

        assert parameters_list.all?(FHIR::Parameters),
               'Not all provided request bodies were Parameters resources.'

        unless canonical_input_provided?(parameters_list)
          add_message(
            'error',
            'No $questionnaire-package request body with a Questionnaire canonical was provided.'
          )
        end

        unless context_id_input_provided?(parameters_list)
          add_message(
            'error',
            'No $questionnaire-package request body with a CRD/DTR context id was provided.'
          )
        end

        unless request_or_encounter_input_provided?(parameters_list)
          add_message(
            'error',
            'No $questionnaire-package request body with an order resource was provided.'
          )
        end

        assert_no_error_messages('Not all required $questionnaire-package input types were provided.')
      end

      def canonical_input_provided?(parameters_list)
        parameters_list.any? do |parameters|
          parameters_include_canonical?(parameters) &&
            !parameters_include_context_id?(parameters) &&
            !parameters_include_request_or_encounter?(parameters)
        end
      end

      def context_id_input_provided?(parameters_list)
        parameters_list.any? do |parameters|
          parameters_include_context_id?(parameters) &&
            !parameters_include_canonical?(parameters) &&
            !parameters_include_request_or_encounter?(parameters)
        end
      end

      def request_or_encounter_input_provided?(parameters_list)
        parameters_list.any? do |parameters|
          parameters_include_request_or_encounter?(parameters) &&
            !parameters_include_canonical?(parameters) &&
            !parameters_include_context_id?(parameters)
        end
      end

      def parameters_include_canonical?(parameters)
        parameters
          .parameter
          .select { |parameter| parameter.name == 'questionnaire' }
          .any? { |parameter| parameter.valueCanonical.present? }
      end

      def parameters_include_context_id?(parameters)
        parameters
          .parameter
          .select { |parameter| parameter.name == 'context' }
          .any? { |parameter| parameter.valueString.present? }
      end

      def parameters_include_request_or_encounter?(parameters)
        parameters
          .parameter
          .select { |parameter| parameter.name == 'order' }
          .any? { |parameter| parameter.resource.present? }
      end
    end
  end
end
