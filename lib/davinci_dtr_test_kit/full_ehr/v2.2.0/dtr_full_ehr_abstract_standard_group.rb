require_relative 'interaction/interaction_wait_test'
require_relative 'interaction/ui_display_and_interaction_attestation_test'
require_relative 'request/dtr_questionnaire_package_request_validation_test'
require_relative 'response/dtr_questionnaire_package_response_validation_test'

module DaVinciDTRTestKit
  # Abstract test group to use for scenarios that require only standard Questionnaires
  # Sets up the interaction and peforms all the validation to confirm that
  # all unique Questionnaires returned by Inferno have been displayed correctly,
  # completed at least once, and stored into the EHR.
  #
  # When extending, set the following config options to control the interaction
  # and verification performed
  # - dtr_workflow_tag: (Required) provide a tag for use in distinguishing requests made
  #   during this interaction test. Used to scope the verifications performed
  #   to just those received during this group's interaction.
  # - qp_single_use: (Optional) set to true if Inferno should return only one successful
  #   response to the $questionnaire-package operation during the interaction.
  #   If set, subsequent calls to the operation will return an OperationOutcome.
  # - qp_response_template_*: (Required) one of the following must be set to specified
  #   to indicate the source of the template that Inferno will use to build for responses
  #   to $questionnaire-package operation requests. Templates come in the form of a FHIR
  #   Parameters resource in json format. See https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Responses
  #   on the wiki for more details on the format for these templates and how Inferno
  #   turns them into actual responses.
  #   - qp_response_template_fixture: path relative to the `lib/davinci_dtr_test_kit/full_ehr/fixtures`
  #     directory pointing to a file containing the template. Used when the scenario
  #     uses developer-specified responses.
  #   - qp_response_template_input: the name of an input that will contain template.
  #     Used when testers can provide their own Questionnaires.
  # - short_circuit_pass_input: (Optional) If testers can decide to not complete any Questionnaires
  #   during this group (e.g., for the must support group when no additional elements need to
  #   be demonstrated), points to an input that indicates that decision. When Questionnaires
  #   are not completed in this way, all tests in this group pass vacuously.
  #   The input must be a radio type that returns a value of 'true' when the tests should
  #   be run.
  # - short_circuit_pass_message: (Optional) Message to use as the vacuous pass message
  #   when tester decides not to run the tests. If not provided a default is used.
  class DTRFullEHRV220AbstractStandard < Inferno::TestGroup
    title 'Standard Questionnaire (Abstract)'
    id :dtr_full_ehr_v220_abstract_standard
    description <<~DESCRIPTION
      Abstract group testing standard qustionnaires only
    DESCRIPTION
    run_as_group

    group do
      title 'Interaction'
      test from: :dtr_full_ehr_v220_interaction_wait
      test from: :dtr_full_ehr_v220_ui_display_and_interaction
    end

    group do
      title '$questionnaire-package'
      test from: :dtr_full_ehr_v220_qp_request_validation
      test from: :dtr_full_ehr_v220_qp_response_validation
    end
  end
end
