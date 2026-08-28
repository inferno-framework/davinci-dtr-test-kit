require_relative '../../../cross_suite/generated_profile_metadata'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePackageBundleMustSupportTest < Inferno::Test
      include QuestionnaireHelper

      MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_q_package_bundle')

      id :dtr_v220_payer_questionnaire_package_bundle_must_support
      title 'Server provides Questionnaire Package Bundle must support elements'
      description %(
        This test confirms that all must support entries defined in the
        [DTR Questionnaire Package Bundle](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-DTR-QPackageBundle.html)
        profile have been observed cumulatively across package Bundles returned during
        previous `$questionnaire-package` tests.

        This includes the following elements:
        - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n        - ")}
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-2'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'Requests must be made prior to running this test.'

        bundles = questionnaire_package_output_parameters_from_operation_responses(requests)
          .flat_map { |parameters| questionnaire_package_bundles(parameters) }
        skip_if bundles.blank?, 'No Questionnaire Package Bundle resources were found to evaluate.'

        assert_must_support_elements_present(bundles, MUST_SUPPORT_METADATA.profile_url,
                                             metadata: MUST_SUPPORT_METADATA)
      end
    end
  end
end
