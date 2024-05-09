
module DaVinciDTRTestKit
  class PayerStaticFormCQLTest < Inferno::Test

    id :dtr_v201_payer_static_form_cql_test
    title 'Questionnaire(s) contains population logic'
    optional
    run do
      skip_if scratch[:questionnaire_bundle].nil?, 'No questionnaire bundle returned.'
      found_bundle = found_questionnaire = false
      # are extensions present in any questionnaire?
      found_min_launch_context = found_min_variable = found_min_pop_context = 
      found_min_init_expression = found_min_candidate_expression = found_min_context_expression = found_min_cqf_lib = false
      info_messages = {}
      scratch[:questionnaire_bundle].parameter.each { |param|
        # param.each { |resource| 
          # Do out put parameters have a bundle?
          if param.resource.resourceType == "Bundle"
            found_bundle = true
            param.resource.entry.each_with_index { |entry, index|
              # Does the bundle have a questionnaire?
              if entry.resource.resourceType == "Questionnaire"
                found_questionnaire = true
                # are extensions present in this questionnaire?
                found_launch_context = found_variable = found_cqf_lib = found_pop_context = 
                found_init_expression = found_candidate_expression = found_context_expression = false
                # check questionnaire extensions
                entry.resource.extension.each { |extension|
                  if extension.url == "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext"
                    found_launch_context = true
                    found_min_launch_context = true
                  end
                  if extension.url == "http://hl7.org/fhir/StructureDefinition/variable"
                    found_variable = true
                    found_min_variable = true
                  end
                  if extension.url == "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext"
                    found_pop_context = true
                    found_min_pop_context = true
                  end
                  if extension.url == "http://hl7.org/fhir/StructureDefinition/cqf-library"
                    found_cqf_lib = true
                    found_min_cqf_lib = true
                  end
                }
                # check questionnaire items
                entry.resource.item.each { |item|
                  # check extensions on items
                  item.extension.each { |item_ext|
                    if item_ext.url == "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression"
                      found_candidate_expression = true
                      found_min_candidate_expression = true
                    end
                    if item_ext == "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression"
                      found_init_expression = true
                      found_min_init_expression = true
                    end
                    if item_ext == "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression"
                      found_context_expression = true
                      found_min_context_expression = true
                    end
                  }
                }

                unless found_launch_context
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no launch context.") }
                end
                unless found_variable
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no variable to query for additional data.") }
                end
                unless found_pop_context
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no item population context.") }
                end
                unless found_cqf_lib
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no cqf library.") }
                end
                unless found_candidate_expression
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no candidate expression.") }
                end
                unless found_init_expression
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no initial expression.") }
                end
                unless found_context_expression 
                  messages << { type: "info", message: format_markdown("[questionnaire #{index+1}] included no context expression.") }
                end
              end
            }
            assert found_questionnaire, "No questionnaires found."
          end
        }
        assert found_bundle, "No questionnaire bundles found."
        assert found_min_launch_context, "No launch context extension found."
        assert found_min_variable, "No variable extension found."
        assert found_min_pop_context, "No population context extension found."
        assert found_min_init_expression, "No initial expression extension found."
        assert found_min_candidate_expression, "No candidate expression extension found."
        assert found_min_context_expression, "No context expression extension found."
        assert found_min_cqf_lib, "No cqf library extension found."
    end
  end
end