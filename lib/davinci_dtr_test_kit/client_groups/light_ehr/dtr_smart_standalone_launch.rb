require_relative 'fhir_launch_context_test'
require_relative 'fhir_context_coverage_test'
require_relative 'fhir_context_references_test'
require 'smart_app_launch/ehr_launch_group_stu2'

module DaVinciDTRTestKit
  class DTRSMARTStandaloneLaunch < SMARTAppLaunch::StandaloneLaunchGroupSTU2
    title 'DTR SMART Standalone Launch'

    id :dtr_smart_standalone_launch
    run_as_group

    test from: :fhir_launch_context_test
    test from: :fhir_context_coverage_test
    test from: :fhir_context_references_test
  end
end
