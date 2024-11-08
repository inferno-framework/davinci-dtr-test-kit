module DaVinciDTRTestKit
  class QuestionnaireResponseValidationTest < Inferno::Test
    include USCoreTestKit::ValidationTest

    id :questionnaire_response_validation
    title 'QuestionnaireResponse resources returned during previous tests conform to the DTR Questionnaire Response'
    description %(
This test verifies resources returned from the first search conform to
the [DTR Questionnaire Response](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    output :dar_code_found, :dar_extension_found

    def resource_type
      'QuestionnaireResponse'
    end

    def scratch_resources
      scratch[:questionnaire_response_resources] ||= {}
    end

    run do
      perform_validation_test(scratch_resources[:all] || [],
                              'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse',
                              '2.1.0',
                              skip_if_empty: true)
    end
  end
end
