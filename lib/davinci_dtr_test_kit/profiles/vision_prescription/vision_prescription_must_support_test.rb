module DaVinciDTRTestKit
  class VisionPrescriptionMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the VisionPrescription resources returned'
    description %(
      This test will look through the VisionPrescription resources
      found previously for the following must support elements:\n

      * VisionPrescription.created
      * VisionPrescription.dateWritten
      * VisionPrescription.encounter
      * VisionPrescription.extension:Coverage-Information
      * VisionPrescription.identifier
      * VisionPrescription.lensSpecification
      * VisionPrescription.lensSpecification.add
      * VisionPrescription.lensSpecification.axis
      * VisionPrescription.lensSpecification.backCurve
      * VisionPrescription.lensSpecification.cylinder
      * VisionPrescription.lensSpecification.diameter
      * VisionPrescription.lensSpecification.duration
      * VisionPrescription.lensSpecification.eye
      * VisionPrescription.lensSpecification.power
      * VisionPrescription.lensSpecification.prism
      * VisionPrescription.lensSpecification.prism.amount
      * VisionPrescription.lensSpecification.prism.base
      * VisionPrescription.lensSpecification.product
      * VisionPrescription.lensSpecification.sphere
      * VisionPrescription.patient
      * VisionPrescription.prescriber
      * VisionPrescription.status
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@355'
    id :vision_prescription_must_support_test

    def resource_type
      'VisionPrescription'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:vision_prescriptions] ||= {}
    end

    run do
      skip_if(vision_prescription_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
