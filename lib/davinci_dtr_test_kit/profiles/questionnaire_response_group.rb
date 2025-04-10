require_relative 'questionnaire_response/questionnaire_response_patient_search'
require_relative 'questionnaire_response/questionnaire_response_context_search'
require_relative 'questionnaire_response/questionnaire_response_read'
require_relative 'questionnaire_response/questionnaire_response_validation'
require_relative 'questionnaire_response/questionnaire_response_create'
require_relative 'questionnaire_response/questionnaire_response_update'
require_relative 'questionnaire_response/questionnaire_response_must_support_test'

module DaVinciDTRTestKit
  class QuestionnaireResponseGroup < Inferno::TestGroup
    title 'DTR QuestionnaireResponse Tests'
    short_description 'Verify support for the server capabilities required by the DTR QuestionnaireResponse Profile'
    description %(
      # Background

    The DTR QuestionnaireResponse sequences verifies that the system under test is able to create and update
    QuestionnaireResponse instances and provide correct responses for QuestionnaireResponse queries. These queries must
    return resources conforming to the [DTR QuestionnaireResponse Profile](http://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-dtr-questionnaireresponse.html).

    # Testing Methodology
    ## Searching
    This test sequence will first perform each required search associated with this resource. This sequence will perform
    searches with the following parameters:

    * `patient`
    * `context`

    ### Search Parameters
    The first search uses the patient(s) from the *Patient IDs* input. Subsequent searches will look for its parameter
    values from the results of the first search. For example, the `context` search in this sequence is performed by
    looking for an existing `context` extension from any of the resources returned in the `patient` search. If a value
    cannot be found this way, the search is skipped.

    ### Search Validation
    Inferno will retrieve up to the first 20 bundle pages of the reply for QuestionnaireResponse resources and save them
    for subsequent tests. Each of these resources is then checked to see if it matches the searched parameters in
    accordance with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if
    a search for `context=Coverage/cov015` returns a QuestionnaireResponse without a link to Coverage `cov015` in the
    `context` extension.

    ## Read
    The ids of each resource returned from the searches are then used to verify that the system under test is able to
    return the correct QuestionnaireResponse resource using the read interaction.

    ## Profile Validation
    Each resource returned from the search step SHALL conform to the [DTR QuestionnaireResponse Profile](http://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-dtr-questionnaireresponse.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Create
    This test sequence will perform create interactions with the provided json QuestionnaireResponse resources. The
    server SHALL be capable of creating a QuestionnaireResponse resource using the create interaction.

    ## Update
    This test sequence will perform update interactions with the provided json QuestionnaireResponse resources. The
    server SHALL be capable of creating a QuestionnaireResponse resource using the update interaction.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the QuestionnaireResponse resources found in the first test for these
    elements.

    )
    id :questionnaire_response_group
    run_as_group

    test from: :questionnaire_response_patient_search
    test from: :questionnaire_response_context_search
    test from: :questionnaire_response_read
    test from: :questionnaire_response_validation
    test from: :questionnaire_response_create
    test from: :questionnaire_response_update
    test from: :questionnaire_response_must_support_test
  end
end
