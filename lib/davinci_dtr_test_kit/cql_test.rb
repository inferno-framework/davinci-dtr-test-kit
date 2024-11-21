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
      scratch[:cqf_reference_libraries] ||= Set.new
    end

    def library_urls
      scratch[:library_urls] ||= Set.new
    end

    def library_names
      scratch[:library_names] ||= Set.new
    end

    def found_questionnaire
      @found_questionnaire ||= false
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

    def verify_questionnaire_extensions(questionnaires)
      assert questionnaires&.any? && questionnaires.all? { |q| q.is_a? FHIR::Questionnaire }, 'No questionnaires found.'
      questionnaires.each_with_index { |q, q_index| check_questionnaire_extensions(q, q_index) }
      check_library_references
      assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
      assert cql_presence['variable'], 'Variable expression logic not written in CQL.'
      assert cql_presence['launch_context'], 'Launch context expression logic not written in CQL.'
      assert cql_presence['pop_context'], 'Population context expression logic not written in CQL.'
    end

    def check_questionnaire_extensions(questionnaire, q_index)
      # are extensions present in this questionnaire?
      found_launch_context = found_variable = found_pop_context = found_cqf_lib = false
      cqf_count = total_cqf_libs(questionnaire.extension)
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

        cqf_reference_libraries.add(extension.valueCanonical)
        found_cqf_lib = true
        extension_presence['found_min_cqf_lib'] = true

        check_for_cql(extension, '', index, q_index, extension.url)
      end
      add_launch_context_messages(found_launch_context, found_variable, found_pop_context, found_cqf_lib, q_index)
      return if cqf_count < 1

      add_formatting_messages(misformatted_expressions, q_index)
      assert misformatted_expressions.compact.empty?, 'Expression in questionnaire misformatted.'
    end

    def verify_questionnaire_items(questionnaires, final_cql_test: false)
      assert questionnaires&.any? && questionnaires.all? { |q| q.is_a? FHIR::Questionnaire }, 'No questionnaires found.'
      questionnaires.each_with_index { |q, q_index| check_questionnaire_items(q, q_index) }

      begin
        assert !found_non_cql_expression, 'Found non-cql expression.'
        assert extension_presence.value?(true), 'No extensions found. Questionnaire must demonstrate prepopulation.'
        assert cql_presence['init_expression'], 'Initial expression logic not written in CQL.'
        assert cql_presence['candidate_expression'], 'Candidate expression logic not written in CQL.'
        assert cql_presence['context_expression'], 'Context expression logic not written in CQL.'
      ensure
        reset_cql_tests if final_cql_test
      end
    end

    def add_launch_context_messages(found_launch_context, found_variable, found_pop_context, found_cqf_lib, q_index)
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

    def add_formatting_messages(misformatted_expressions, q_index)
      misformatted_expressions.compact.each do |idx|
        messages << { type: 'info',
                      message: format_markdown("[expression #{idx + 1}] in [questionnaire #{q_index + 1}]
                      does not begin with a reference to an included library name.") }
      end
    end

    def total_cqf_libs(extensions)
      cqf_count = 0
      extensions.each do |extension|
        next unless extension.url == 'http://hl7.org/fhir/StructureDefinition/cqf-library'

        cqf_count += 1
      end
      cqf_count
    end

    def add_item_messages(found_item_expressions, q_index)
      unless found_item_expressions['found_candidate_expression']
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no candidate expression.") }
      end
      unless found_item_expressions['found_init_expression']
        messages << { type: 'info',
                      message: format_markdown("[questionnaire #{q_index + 1}] included no initial expression.") }
      end
      return if found_item_expressions['found_context_expression']

      messages << { type: 'info',
                    message: format_markdown("[questionnaire #{q_index + 1}] included no context expression.") }
    end

    def check_questionnaire_items(questionnaire, q_index)
      # are expressions present in this questionnaire?
      found_item_expressions = { 'found_init_expression' => false,
                                 'found_candidate_expression' => false,
                                 'found_context_expression' => false }
      cqf_count = total_cqf_libs(questionnaire.extension)
      misformatted_expressions = []

      # check questionnaire items
      questionnaire.item.each_with_index do |item, index|
        misformatted_expressions.concat(check_nested_items(item, index, q_index, found_item_expressions, item.linkId))
        # check extensions on items
        item.extension.each do |item_ext|
          misformatted_expressions << check_item_extension(item_ext,
                                                           index, q_index, found_item_expressions, item.linkId)
        end
      end
      add_item_messages(found_item_expressions, q_index)
      # only care about formatting when there are multiple cqf libs
      return if cqf_count < 1

      misformatted_expressions.compact.to_set.each do |idx|
        messages << { type: 'info',
                      message: format_markdown("[item #{idx + 1}] in [questionnaire #{q_index + 1}]
                      contains expression that does not begin with a reference to an included library name.") }
      end
      assert misformatted_expressions.compact.to_set.empty?, 'Expression in questionnaire misformatted.'
    end

    def evaluate_library(library)
      found_cql = found_elm = false
      library.content.each do |content|
        if content.data.nil?
          messages << { type: 'info',
                        message: format_markdown("[library #{library.url}] content element included no data.") }
        end
        if content.contentType == 'text/cql'
          found_cql = true
        elsif content.contentType == 'application/elm+json'
          found_elm = true
        else
          messages << { type: 'info',
                        message: format_markdown("[library #{library.url}] has non-cql/elm content.") }
          true
        end
        next unless library_names.include? library.name

        found_duplicate_library_name = true
        messages << { type: 'info', message: format_markdown("[library #{library.url}] has a name,
         #{library.name}, that is already included in the bundle.") }
        assert !found_duplicate_library_name, 'Found duplicate library names - all names must be unique.'
      end
      assert found_cql, "[library #{library.url}] does not include CQL."
      assert found_elm, "[library #{library.url}] does not include ELM."
    end

    def check_libraries(questionnaire_bundles)
      libraries = extract_libraries_from_bundles(questionnaire_bundles)

      assert libraries.any?, 'No Libraries found.'

      libraries.each do |lib|
        library_urls.add(lib.url) unless lib.url.nil?
        evaluate_library(lib)
        library_names.add(lib.name)
      end
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
          misformatted_nested_expressions << check_item_extension(item_ext, index, q_index, found_item_expressions,
                                                                  link_id)
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
      messages << if link_id.blank?
                    { type: 'info',
                      message: format_markdown("[extension #{index + 1}] in [questionnaire #{q_index + 1}]
                          contains expression that does not have content type of cql
                          (URL: #{url}).") }
                  else
                    { type: 'info',
                      message: format_markdown("[item #{index + 1}] in [questionnaire #{q_index + 1}]
                          contains expression that does not have content type of cql
                          (linkId: #{link_id}, URL: #{url}).") }
                  end
    end

    def extract_contained_questionnaires(questionnaire_responses)
      questionnaire_responses&.filter_map do |qr|
        qr.contained&.filter { |resource| resource.is_a?(FHIR::Questionnaire) }
      end&.flatten&.compact
    end

    def extract_questionnaires_from_bundles(questionnaire_bundles)
      questionnaire_bundles.filter_map do |qb|
        qb.entry.filter_map { |entry| entry.resource if entry.resource.is_a?(FHIR::Questionnaire) }
      end&.flatten&.compact
    end

    def extract_libraries_from_bundles(questionnaire_bundles)
      questionnaire_bundles.filter_map do |qb|
        qb.entry.filter_map { |entry| entry.resource if entry&.resource.is_a?(FHIR::Library) }
      end&.flatten&.compact
    end
  end
end
