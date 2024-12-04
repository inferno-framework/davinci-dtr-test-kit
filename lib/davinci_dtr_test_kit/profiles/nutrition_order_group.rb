require_relative 'nutrition_order/nutrition_order_read'
require_relative 'nutrition_order/nutrition_order_validation'

module DaVinciDTRTestKit
  class NutritionOrderGroup < Inferno::TestGroup
    title 'CRD NutritionOrder Tests'
    short_description 'Verify support for the server capabilities required by the CRD NutritionOrder Profile'
    description %(
      # Background

    The CRD NutritionOrder sequence verifies that the system under test is
    able to provide correct responses for NutritionOrder queries. These queries
    must return resources conforming to the [CRD NutritionOrder Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-nutritionorder)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    This test sequence will first perform the required read associated
    with this resource. The server SHOULD be capable of returning a
    NutritionOrder resource using the read interaction.

    ## Profile Validation
    Each resource returned from the first read is expected to conform to
    the [CRD NutritionOrder Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-nutritionorder).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :nutrition_order_group
    run_as_group

    input :nutrition_order_ids

    test from: :nutrition_order_read
    test from: :nutrition_order_validation
  end
end
