require_relative 'questionnaire_response/questionnaire_response_patient_search'
require_relative 'questionnaire_response/questionnaire_response_context_search'
require_relative 'questionnaire_response/questionnaire_response_read'
require_relative 'questionnaire_response/questionnaire_response_validation'
require_relative 'questionnaire_response/questionnaire_response_create'
require_relative 'questionnaire_response/questionnaire_response_update'

module DaVinciDTRTestKit
  class QuestionnaireResponseGroup < Inferno::TestGroup
    title 'DTR QuestionnaireResponse Tests'
    short_description 'Verify support for the server capabilities required by the DTR QuestionnaireResponse Profile'
    description %(
      # Background

    The DTR QuestionnaireResponse sequence verifies that the system under test is
    able to provide correct responses for QuestionnaireResponse queries. These queries
    must return resources conforming to the [DTR QuestionnaireResponse Profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse).

    # Testing Methodology
    ## Searching
    This test sequence will first perform each required search associated
    with this resource. This sequence will perform searches with the
    following parameters:

    * patient

    ### Search Parameters
    The first search uses the patient(s) from the patient_ids input. Any subsequent searches will look for its parameter
    values from the results of the first search. For example, the `identifier`
    search in the patient sequence is performed by looking for an existing
    `Patient.identifier` from any of the resources returned in the `_id`
    search. If a value cannot be found this way, the search is skipped.

    ### Search Validation
    Inferno will retrieve up to the first 20 bundle pages of the reply for
    QuestionnaireResponse resources and save them for subsequent tests. Each of
    these resources is then checked to see if it matches the searched
    parameters in accordance with [FHIR search
    guidelines](https://www.hl7.org/fhir/search.html). The test will fail,
    for example, if a Patient search for `gender=male` returns a `female`
    patient.

    ## Read
    The id of each resource returned from the first search is then used to verify that the system under test is able to
    return the correct QuestionnaireResponse resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [DTR QuestionnaireResponse Profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse).
    Each element is checked against terminology binding and cardinality requirements.

    ## Create
    This test sequence will perform create interactions with the provided json
    QuestionnaireResponse resources. The server SHOULD be capable of creating a
    QuestionnaireResponse resource using the create interaction.

    ## Update
    This test sequence will perform update interactions with the provided json
    QuestionnaireResponse resources. The server SHOULD be capable of creating a
    QuestionnaireResponse resource using the update interaction.
          )
    id :questionnaire_response_group
    run_as_group

    test from: :questionnaire_response_patient_search
    test from: :questionnaire_response_context_search
    test from: :questionnaire_response_read
    test from: :questionnaire_response_validation
    test from: :questionnaire_response_create
    test from: :questionnaire_response_update
  end
end
