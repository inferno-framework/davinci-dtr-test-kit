module DaVinciDTRTestKit
  module CQLTest
    def extension_requirements
      @extension_requirements ||= { 'found_min_launch_context' => false, 'found_min_variable' => false,
                                    'found_min_pop_context' => false, 'found_min_init_expression' => false,
                                    'found_min_candidate_expression' => false, 'found_min_context_expression' => false,
                                    'found_min_cqf_lib' => false }
    end

    def cqf_reference_libraries
      @cqf_reference_libraries ||= Set.new
    end

    def library_urls
      @@library_urls ||= Set.new
    end

    def library_names
      @@library_names ||= Set.new
    end

    def found_questionnaire
      @found_questionnaire ||= false
    end

    def multiple_cqf
      @@multiple_cqf ||= false
    end

    def found_bad_library_reference
      @@found_bad_library_reference ||= false
    end

    def found_duplicate_library_name
      @found_duplicate_library_name ||= false
    end

    def found_non_cql_elm_library
      @found_non_cql_elm_library ||= false
    end

    def found_non_cql_expression
      @found_non_cql_expression ||= false
    end

    def reset_cql_tests
      library_names.clear
      library_urls.clear
      cqf_reference_libraries.clear
      extension_requirements.each_key { |k| extension_requirements[k] = false }
    end

    def questionnaire_extensions_test(response)
      resource = process_response(response)
      assert !resource.nil?, 'Response is null or not a valid type.'
      found_questionnaire = false
      if resource.instance_of? Array
        resource.each do |individual_resource|
          next unless individual_resource.resourceType == 'QuestionnaireResponse'

          individual_resource.contained.each_with_index do |questionnaire, q_index|
            # Do out put parameters have a bundle?
            next unless questionnaire.resourceType == 'Questionnaire'

            # check the libraries first so references in questionnaires can be checked after
            found_questionnaire = true
            check_questionnaire_extensions(questionnaire, q_index)
          end
        end
      elsif resource.resourceType == 'Parameters'
        resource.parameter.each do |param|
          # Do out put parameters have a bundle?
          next unless param.resource.resourceType == 'Bundle'

          param.resource.entry.each_with_index do |entry, q_index|
            # check questionnaire extensions
            next unless entry.resource.resourceType == 'Questionnaire'

            found_questionnaire = true
            check_questionnaire_extensions(entry, q_index)
          end
        end
      end
      check_library_references
      assert found_questionnaire, 'No questionnaires found.'
      assert extension_requirements['found_min_cqf_lib'], 'No cqf library extension found.'
      assert extension_requirements['found_min_variable'], 'No variable extension found.'
      assert extension_requirements['found_min_launch_context'], 'No launch context extension found.'
      assert extension_requirements['found_min_pop_context'], 'No population context extension found.'
    end

    def check_questionnaire_extensions(questionnaire, q_index)
      # are extensions present in this questionnaire?
      found_launch_context = found_variable = found_pop_context = found_cqf_lib = false
      questionnaire.extension.each do |extension|
        if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext'
          found_launch_context = true
          extension_requirements['found_min_launch_context'] = true
        end
        if extension.url == 'http://hl7.org/fhir/StructureDefinition/variable'
          found_variable = true
          extension_requirements['found_min_variable'] = true
        end
        if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext'
          found_pop_context = true
          extension_requirements['found_min_pop_context'] = true
        end
        next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

        cqf_reference_libraries.add(extension.valueCanonical)
        found_cqf_lib = true
        extension_requirements['found_min_cqf_lib'] = true
      end
      unless found_launch_context
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no launch context.") }
      end
      unless found_variable
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}]
                       included no variable to query for additional data.") }
      end
      unless found_pop_context
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}]
                       included no item population context.") }
      end
      return if found_cqf_lib

      messages << { type: 'info',
                    message: format_markdown("[questionnaire #{q_index + 1}]
                     included no cqf library.") }
    end

    def check_library_references
      missing_references = cqf_reference_libraries.select do |url|
        library_urls.exclude? url
      end
      assert missing_references.empty?,
             "Some libraries referenced by cqf-libraries were not found: #{missing_references.join(', ')}"
    end

    def questionnaire_expressions_test(response, final_cql_test)
      resource = process_response(response)
      assert !resource.nil?, 'Response is null or not a valid type.'
      found_bundle = found_questionnaire = false
      # are extensions present in any questionnaire?
      if resource.instance_of? Array
        resource.each_with_index do |individual_resource, q_index|
          next unless individual_resource.resourceType == 'QuestionnaireResponse'

          individual_resource.contained.each do |questionnaire|
            # Do out put parameters have a bundle?
            next unless questionnaire.resourceType == 'Questionnaire'

            # check the libraries first so references in questionnaires can be checked after
            found_questionnaire = true
            check_questionnaire_expressions(questionnaire, q_index)
          end
        end
      elsif resource.resourceType == 'Parameters'
        resource.parameter.each do |param|
          # Do out put parameters have a bundle?
          next unless param.resource.resourceType == 'Bundle'

          found_bundle = true
          # check the libraries first so references in questionnaires can be checked after
          param.resource.entry.each_with_index do |entry, q_index|
            if entry.resource.resourceType == 'Questionnaire'
              found_questionnaire = true
              check_questionnaire_expressions(entry.resource, q_index)
            end
          end
        end
        assert found_bundle, 'No questionnaire bundles found.'
      end
      begin
        assert found_questionnaire, 'No questionnaires found.'
        assert !found_non_cql_expression, 'Found non-cql expression.'
        assert !found_bad_library_reference, 'Found expression with no or incorrect reference to library name.'
        assert extension_requirements['found_min_init_expression'], 'No initial expression extension found.'
        assert extension_requirements['found_min_candidate_expression'], 'No candidate expression extension found.'
        assert extension_requirements['found_min_context_expression'], 'No context expression extension found.'
      ensure
        reset_cql_tests if final_cql_test
      end
    end

    def check_questionnaire_expressions(questionnaire, q_index)
      # are expressions present in this questionnaire?
      found_init_expression = found_candidate_expression = found_context_expression = false
      # check questionnaire items
      questionnaire.item.each_with_index do |item, index|
        # check extensions on items
        item.extension.each do |item_ext|
          if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
            found_candidate_expression = true
            extension_requirements['found_min_candidate_expression'] = true
            unless item_ext.valueExpression.language == 'text/cql'
              messages << { type: 'info',
                            message: format_markdown("[expression #{index + 1}] in [questionnaire #{q_index + 1}]
                             does not have content type of cql.") }
              true
            end
            if multiple_cqf && library_names.none? do |name|
                 item_ext.valueExpression.expression.start_with? "\"#{name}\""
               end
              messages << { type: 'info',
                            message: format_markdown("[expression #{index + 1}] in [questionnaire #{q_index + 1}] does not begin with a reference to an included library name.") }
            end
          end
          if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
            found_init_expression = true
            extension_requirements['found_min_init_expression'] = true
            unless item_ext.valueExpression.language == 'text/cql'
              messages << { type: 'info',
                            message: format_markdown("[expression #{index + 1}] in
                            [questionnaire #{q_index + 1}] does not have content type of cql.") }
              true
            end
            if multiple_cqf && library_names.none? do |name|
                 item_ext.valueExpression.expression.start_with? "\"#{name}\""
               end
              messages << { type: 'info',
                            message: format_markdown("[expression #{index + 1}] in [questionnaire #{q_index + 1}] does not begin with a reference to an included library name.") }
            end
          end
          next unless item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression'

          found_context_expression = true
          extension_requirements['found_min_context_expression'] = true
          next if item_ext.valueExpression.language == 'text/cql'

          messages << { type: 'info',
                        message: format_markdown("[expression #{index + 1}] in [questionnaire #{q_index + 1}] does
                         not have content type of cql.") }
          next unless multiple_cqf && library_names.none? do |name|
                        item_ext.valueExpression.expression.start_with? "\"#{name}\""
                      end

          messages << { type: 'info',
                        message: format_markdown("[expression #{index + 1}] in [questionnaire #{q_index + 1}] does not begin with a reference to an included library name.") }
        end
      end
      unless found_candidate_expression
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no candidate expression.") }
      end
      unless found_init_expression
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no initial expression.") }
      end
      return if found_context_expression

      messages << { type: 'info',
                    message: format_markdown("[questionnaire #{q_index + 1}] included no context expression.") }
    end

    def check_libraries(payer_response)
      resource = process_response(payer_response)
      assert !resource.nil?, 'Response is null or not a valid type.'
      found_bundle = found_libraries = false
      # are extensions present in any questionnaire?
      resource.parameter.each do |param|
        # Do out put parameters have a bundle?
        next unless param.resource.resourceType == 'Bundle'

        found_bundle = true
        # check the libraries first so references in questionnaires can be checked after
        param.resource.entry.each_with_index do |entry, index|
          next unless entry.resource.resourceType == 'Library'

          found_libraries = true
          found_cql = found_elm = false
          library_urls.add(entry.resource.url) unless entry.resource.url.nil?
          entry.resource.content.each do |content|
            # TODO: validate CQL
            if content.data.nil?
              messages << { type: 'info',
                            message: format_markdown("[library #{index + 1}] content element included no data.") }
            end
            if content.contentType == 'text/cql'
              found_cql = true
            elsif content.contentType == 'application/elm+json'
              found_elm = true
            else
              messages << { type: 'info',
                            message: format_markdown("[library #{index + 1}] has non-cql/elm content.") }
              true
            end
            next unless library_names.include? entry.resource.name

            found_duplicate_library_name = true
            messages << { type: 'info', message: format_markdown("[library #{index + 1}] has a name,
             #{entry.resource.name}, that is already included in the bundle.") }
            assert !found_duplicate_library_name, 'Found duplicate library names - all names must be unique.'
          end
          library_names.add(entry.resource.name)
          assert found_cql, "[library #{index + 1}] does not include CQL."
          assert found_elm, "[library #{index + 1}] does not include ELM."
        end
        assert found_libraries, 'No Libraries found.'
      end
      assert found_bundle, 'No questionnaire bundles found.'
    end

    def process_response(response)
      if response.instance_of?(FHIR::Parameters) || response.instance_of?(FHIR::QuestionnaireResponse)
        return response
      elsif response.instance_of? Array
        questionnaire_responses = []
        response.each do |resource|
          if FHIR.from_contents(resource.response_body).resourceType == 'QuestionnaireResponse'
            questionnaire_responses << FHIR.from_contents(resource.response_body)
          end
          next unless resource.instance_of? Inferno::Entities::Request

          if FHIR.from_contents(resource.response_body).resourceType == 'Questionnaire' ||
             FHIR.from_contents(resource.response_body).resourceType == 'Parameters'
            return FHIR.from_contents(resource.response_body)
          end
        end
        return questionnaire_responses
      end

      nil
    end
  end
end
