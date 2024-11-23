require_relative '../../validation_test'

module DaVinciDTRTestKit
  class TaskValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

    title 'Task resources returned during previous tests conform to the CDex Task'
    description %(
This test verifies resources returned from the first read conform to
the [CDex Task](https://hl7.org/fhir/us/davinci-cdex/STU2/StructureDefinition-cdex-task-attachment-request).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :task_validation
    input :task_resources

    def resource_type
      'Task'
    end

    run do
      perform_profile_validation_test(task_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-cdex/StructureDefinition/cdex-task-attachment-request|2.0.0')
    end
  end
end
