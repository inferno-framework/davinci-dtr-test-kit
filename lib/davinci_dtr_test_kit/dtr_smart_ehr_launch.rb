require_relative 'fhir_launch_context_test'
require_relative 'coverage_context_read'
require_relative 'context_references_test'
require 'smart_app_launch/ehr_launch_group_stu2'

module DaVinciDTRTestKit
  class DTRSMARTEHRLaunch < SMARTAppLaunch::EHRLaunchGroupSTU2
    title 'DTR SMART EHR Launch'

    id :dtr_smart_ehr_launch
    run_as_group

    test from: :fhir_launch_context
    test from: :coverage_context_read
    test from: :fhir_context_references
  end
end
