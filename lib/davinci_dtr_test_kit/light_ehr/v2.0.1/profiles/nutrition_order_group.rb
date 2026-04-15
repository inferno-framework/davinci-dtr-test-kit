require_relative 'nutrition_order/nutrition_order_read'
require_relative 'nutrition_order/nutrition_order_validation'
require_relative 'nutrition_order/nutrition_order_must_support_test'

module DaVinciDTRTestKit
  class NutritionOrderGroup < Inferno::TestGroup
    title 'CRD NutritionOrder Tests'
    short_description 'Verify support for the server capabilities required by the CRD NutritionOrder Profile'
    description %(
      # Background

    The CRD NutritionOrder sequence verifies that the system under test is
    able to provide correct responses for NutritionOrder queries. These queries
    must return resources conforming to the [CRD NutritionOrder Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-nutritionorder.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each NutritionOrder resource id provided in
    the NutritionOrder IDs input. The server SHOULD be capable of returning a
    NutritionOrder resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD NutritionOrder Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-communicationrequest.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the NutritionOrder resources found in the first test for these
    elements.

    )
    id :nutrition_order_group
    optional
    run_as_group

    input :nutrition_order_ids,
          title: 'Nutrition Order IDs',
          description: 'Comma separated list of NutritionOrder IDs',
          optional: true

    test from: :nutrition_order_read
    test from: :nutrition_order_validation
    test from: :nutrition_order_must_support_test
  end
end
