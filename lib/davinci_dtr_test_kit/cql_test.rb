module DaVinciDTRTestKit
  module CQLTest
    def extension_presence
      @extension_presence ||= { 'found_min_launch_context' => false, 'found_min_variable' => false,
                                'found_min_pop_context' => false, 'found_min_init_expression' => false,
                                'found_min_candidate_expression' => false, 'found_min_context_expression' => false,
                                'found_min_cqf_lib' => false }
    end

    def cql_presence
      @cql_presence ||= { 'launch_context' => true, 'variable' => true,
                          'pop_context' => true, 'init_expression' => true,
                          'candidate_expression' => true, 'context_expression' => true }
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
      extension_presence.each_key { |k| extension_presence[k] = false }
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
            check_questionnaire_extensions(entry.resource, q_index)
            ## NEED TO FIGURE OUT HOW TO FAIL TEST WHEN POORLY FORMATTED EXPRESSIONS FOUND
          end
        end
      end
      check_library_references
      assert found_questionnaire, 'No questionnaires found.'
      assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
      assert cql_presence['variable'], 'Variable expression logic not written in CQL.'
      assert cql_presence['launch_context'], 'Launch context expression logic not written in CQL.'
      assert cql_presence['pop_context'], 'Population context expression logic not written in CQL.'
    end

    def questionnaire_items_test(response, final_cql_test)
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
            check_questionnaire_items(questionnaire, q_index)
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
              check_questionnaire_items(entry.resource, q_index)
            end
          end
        end
        assert found_bundle, 'No questionnaire bundles found.'
      end
      begin
        assert found_questionnaire, 'No questionnaires found.'
        assert !found_non_cql_expression, 'Found non-cql expression.'
        assert !found_bad_library_reference, 'Found expression with no or incorrect reference to library name.'
        assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
        assert cql_presence['init_expression'], 'Initial expression logic not written in CQL.'
        assert cql_presence['candidate_expression'], 'Candidate expression logic not written in CQL.'
        assert cql_presence['context_expression'], 'Context expression logic not written in CQL.'
      ensure
        reset_cql_tests if final_cql_test
      end
    end

    def check_questionnaire_extensions(questionnaire, q_index)
      # are extensions present in this questionnaire?
      found_launch_context = found_variable = found_pop_context = found_cqf_lib = false
      cqf_count = 0
      misformatted_expressions = []
      questionnaire.extension.each_with_index do |extension, index|
        if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext'
          found_launch_context = true
          extension_presence['found_min_launch_context'] = true
          check_for_cql(extension, 'launch_context', index, q_index, extension.url)
          misformatted_expressions << check_expression_format(extension, index)
        end
        if extension.url == 'http://hl7.org/fhir/StructureDefinition/variable'
          found_variable = true
          extension_presence['found_min_variable'] = true
          check_for_cql(extension, 'variable', index, q_index, extension.url)
          misformatted_expressions << check_expression_format(extension, index)
        end
        if extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext'
          found_pop_context = true
          extension_presence['found_min_pop_context'] = true
          check_for_cql(extension, 'pop_context', index, q_index, extension.url)
          misformatted_expressions << check_expression_format(extension, index)
        end
        next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

        cqf_count += 1
        cqf_reference_libraries.add(extension.valueCanonical)
        found_cqf_lib = true
        extension_presence['found_min_cqf_lib'] = true

        check_for_cql(extension, '', index, q_index, extension.url)
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
      unless found_cqf_lib
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}]
                      included no cqf library.") }
      end
      return if cqf_count < 1

      misformatted_expressions.compact.each do |idx|
        messages << { type: 'info',
                      message: format_markdown("[expression #{idx + 1}] in [questionnaire #{q_index + 1}]
                      does not begin with a reference to an included library name.") }
      end
      assert misformatted_expressions.compact.empty?, 'Expression in questionnaire misformatted.'
    end

    def check_questionnaire_items(questionnaire, q_index)
      # are expressions present in this questionnaire?
      found_item_expressions = { 'found_init_expression' => false,
                                 'found_candidate_expression' => false,
                                 'found_context_expression' => false }
      cqf_count = 0
      misformatted_expressions = []
      questionnaire.extension.each do |extension|
        next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

        cqf_count += 1
      end
      # check questionnaire items
      questionnaire.item.each_with_index do |item, index|
        misformatted_expressions.concat(check_nested_items(item, index, q_index, found_item_expressions, item.linkId))
        # check extensions on items
        item.extension.each do |item_ext|
          misformatted_expressions << check_item_extension(item_ext,
                                                           index, q_index, found_item_expressions, item.linkId)
        end
      end
      unless found_item_expressions['found_candidate_expression']
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no candidate expression.") }
      end
      unless found_item_expressions['found_init_expression']
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no initial expression.") }
      end
      unless found_item_expressions['found_context_expression']
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no context expression.") }
      end
      return if cqf_count < 1

      misformatted_expressions.compact.to_set.each do |idx|
        messages << { type: 'info',
                      message: format_markdown("[item #{idx + 1}] in [questionnaire #{q_index + 1}]
                      contains expression that does not begin with a reference to an included library name.") }
      end
      assert misformatted_expressions.compact.to_set.empty?, 'Expression in questionnaire misformatted.'
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

    def check_library_references
      missing_references = cqf_reference_libraries.select do |url|
        library_urls.exclude? url
      end
      assert missing_references.empty?,
             "Some libraries referenced by cqf-libraries were not found: #{missing_references.join(', ')}"
    end

    def check_item_extension(item_ext, index, q_index, found_item_expressions, link_id)
      if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'
        found_item_expressions['found_candidate_expression'] = true
        extension_presence['found_min_candidate_expression'] = true
        check_for_cql(item_ext, 'candidate_expression', index, q_index, item_ext.url, link_id)
        return check_expression_format(item_ext, index)
      end
      if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
        found_item_expressions['found_init_expression'] = true
        extension_presence['found_min_init_expression'] = true
        check_for_cql(item_ext, 'init_expression', index, q_index, item_ext.url, link_id)
        return check_expression_format(item_ext, index)
      end
      if item_ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression'
        found_item_expressions['found_context_expression'] = true
        extension_presence['found_min_context_expression'] = true
        check_for_cql(item_ext, 'context_expression', index, q_index, item_ext.url, link_id)
        return check_expression_format(item_ext, index)
      end
      check_for_cql(item_ext, '', index, q_index, item_ext.url, link_id)
    end

    def check_nested_items(item, index, q_index, found_item_expressions, link_id)
      misformatted_nested_expressions = []
      item.item.each do |nested_item|
        check_nested_items(nested_item, index, q_index, found_item_expressions, nested_item.linkId)
        nested_item.extension.each do |item_ext|
          misformatted_nested_expressions << check_item_extension(item_ext, index, q_index, found_item_expressions, link_id)
        end
      end
      misformatted_nested_expressions.compact
    end

    def check_expression_format(item_ext, index)
      return unless library_names.none?

      expression_passes = false
      library_names.each do |name|
        if item_ext.valueExpression.expression.start_with? "\"#{name}\""
          expression_passes = true
          break
        end
      end
      index unless expression_passes
    end

    def check_for_cql(extension, extension_name, index, q_index, url, link_id = '')
      return if extension.valueExpression.nil?
      return if extension.valueExpression.language == 'text/cql'

      cql_presence[extension_name] = false unless extension_name.blank?
      if link_id.blank?
        messages << { type: 'info',
                      message: format_markdown("[extension #{index + 1}] in [questionnaire #{q_index + 1}]
                          contains expression that does not have content type of cql
                          (URL: #{url}).") }
      else
        messages << { type: 'info',
                      message: format_markdown("[item #{index + 1}] in [questionnaire #{q_index + 1}]
                          contains expression that does not have content type of cql
                          (linkId: #{link_id}, URL: #{url}).") }
      end
    end

    def process_response(response)
      if response.instance_of?(FHIR::Parameters) || response.instance_of?(FHIR::QuestionnaireResponse)
        return response
      elsif response.instance_of? Array
        questionnaire_responses = []
        response.each do |resource|
          fhir_resource = FHIR.from_contents(resource.response_body)
          questionnaire_responses << fhir_resource if fhir_resource.resourceType == 'QuestionnaireResponse'
          next unless resource.instance_of? Inferno::Entities::Request

          if fhir_resource.resourceType == 'Questionnaire' || fhir_resource.resourceType == 'Parameters'
            return fhir_resource
          end
        end
        return questionnaire_responses
      end

      nil
    end
  end
end
