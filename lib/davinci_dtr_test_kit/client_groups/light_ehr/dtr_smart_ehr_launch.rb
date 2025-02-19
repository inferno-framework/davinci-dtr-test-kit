require_relative 'fhir_launch_context_test'
require_relative 'fhir_context_coverage_test'
require_relative 'fhir_context_references_test'
require 'smart_app_launch/ehr_launch_group_stu2'

module DaVinciDTRTestKit
  class DTRSMARTEHRLaunch < SMARTAppLaunch::EHRLaunchGroupSTU2
    title 'DTR SMART EHR Launch'
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@117'

    id :dtr_smart_ehr_launch
    run_as_group

    test from: :fhir_launch_context_test
    test from: :fhir_context_coverage_test
    test from: :fhir_context_references_test
  end
end
