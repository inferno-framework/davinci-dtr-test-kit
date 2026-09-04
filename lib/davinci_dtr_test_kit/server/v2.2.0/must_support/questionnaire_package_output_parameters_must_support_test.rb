require_relative '../../../cross_suite/generated_profile_metadata'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePackageOutputParametersMustSupportTest < Inferno::Test
      include QuestionnaireHelper

      MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_qpackage_output_parameters')

      id :dtr_v220_payer_questionnaire_package_output_parameters_must_support
      title 'Server provides Questionnaire Package Output Parameters must support elements'
      description %(
        This test confirms that all must support elements defined in the
        [DTR Questionnaire Package Output Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-output-parameters.html)
        profile have been observed cumulatively across `$questionnaire-package` responses
        returned during previous tests.

        This includes the following elements:
        - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n        - ")}
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-2'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'Requests must be made prior to running this test.'

        parameters = questionnaire_package_output_parameters_from_operation_responses(requests)
        skip_if parameters.blank?, 'No Questionnaire Package Output Parameters resources were found to evaluate.'

        assert_must_support_elements_present(parameters, MUST_SUPPORT_METADATA.profile_url,
                                             metadata: MUST_SUPPORT_METADATA)
      end
    end
  end
end
