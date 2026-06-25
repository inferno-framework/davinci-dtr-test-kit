require_relative '../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module ClientSimulation
      def questionnaire_interaction(fhir_base_url, questionnaire_package_parameters, questionnaire_response_templates)
        adaptive_questionnaire_interaction(fhir_base_url, questionnaire_package_parameters,
                                           questionnaire_response_templates)
      end

      def static_questionnaire_interaction(fhir_base_url, questionnaire_package_parameters)
        qp_response = make_questionnaire_package_request(fhir_base_url, questionnaire_package_parameters)
        package_bundles = extract_response_package_bundles(qp_response)
        find_and_expand_value_sets(package_bundles, fhir_base_url)
      end

      def adaptive_questionnaire_interaction(fhir_base_url, questionnaire_package_parameters,
                                             questionnaire_response_templates)
        qp_response = make_questionnaire_package_request(fhir_base_url, questionnaire_package_parameters)
        package_bundles = extract_response_package_bundles(qp_response)
        find_and_expand_value_sets(package_bundles, fhir_base_url)
        adaptive_questionnaire_details = extract_adaptive_questionnaires(package_bundles,
                                                                         questionnaire_response_templates)
        adaptive_questionnaire_details.each do |detail|
          request_adaptive_questionnaire_using_next_question(detail, fhir_base_url)
        end
      end

      private

      #########################################################################
      # $questionnaire-package request and response processing
      #########################################################################

      def make_questionnaire_package_request(fhir_base_url, parameters)
        tags = [QUESTIONNAIRE_TAG]
        fhir_operation("#{fhir_base_url.chomp('/')}/Questionnaire/$questionnaire-package",
                       body: parameters,
                       headers: { 'Content-Type': 'application/fhir+json' },
                       tags:)
      end

      def extract_response_package_bundles(qp_response)
        qp_response_parameters = extract_response_parameters(qp_response)
        return [] unless qp_response_parameters.present?

        qp_response_parameters.parameter.select do |param|
          param.name == 'packagebundle' && param.resource.is_a?(FHIR::Bundle)
        end.map(&:resource)
      end

      def extract_response_parameters(qp_response)
        return nil unless qp_response.status.to_s.starts_with?('2')

        qp_response_parameters = FHIR.from_contents(qp_response.response_body)
        qp_response_parameters.is_a?(FHIR::Parameters) ? qp_response_parameters : nil
      rescue JSON::ParserError
        nil
      end

      #########################################################################
      # ValueSet/$expand
      #########################################################################

      def find_and_expand_value_sets(package_bundles, fhir_base_url)
        package_bundles.each do |bundle|
          bundle.entry.each do |entry|
            next unless expandable_value_set?(entry.resource)

            expand_value_set(entry.resource, fhir_base_url)
          end
        end
      end

      def expandable_value_set?(resource)
        resource.is_a?(FHIR::ValueSet) &&
          resource.expansion.blank? &&
          resource.url.present?
      end

      def expand_value_set(value_set, fhir_base_url)
        tags = [VALUE_SET_EXPAND_TAG]
        canonical = canonical_url_for_resource(value_set)
        parameters = FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(name: 'url', valueUri: canonical)
          ]
        )

        fhir_operation("#{fhir_base_url.chomp('/')}/ValueSet/$expand",
                       body: parameters,
                       headers: { 'Content-Type': 'application/fhir+json' },
                       tags:)
      end

      #########################################################################
      # $next-question request sequence
      #########################################################################

      def request_adaptive_questionnaire_using_next_question(adaptive_questionnaire_detail, fhir_base_url)
        base_url = next_question_base_url(adaptive_questionnaire_detail[:questionnaire], fhir_base_url)
        template = adaptive_questionnaire_detail[:template]

        form = adaptive_questionnaire_detail[:questionnaire_response]
        loop do
          nq_response = make_next_question_request(base_url, form)
          returned_form = extract_next_question_response(nq_response)
          break unless returned_form.present?

          if form_completed?(returned_form)
            form = returned_form
            break
          end

          new_items = identify_new_items(form, returned_form)
          break unless new_items.present?
          break unless new_answers?(new_items, template)

          form = add_new_answers(returned_form, new_items, template)
        end

        return if form_completed?(form)

        add_message('warning', '$next-question requests did not result in a completed form')
      end

      def make_next_question_request(fhir_base_url, questionnaire_response)
        tags = [NEXT_TAG]
        fhir_operation("#{fhir_base_url}/Questionnaire/$next-question",
                       body: questionnaire_response,
                       headers: { 'Content-Type': 'application/fhir+json' },
                       tags:)
      end

      def extract_next_question_response(nq_response)
        return nil unless nq_response.status.to_s.starts_with?('2')

        extract_next_question_response_form(nq_response)
      end

      def extract_next_question_response_form(nq_response)
        resource = FHIR.from_contents(nq_response.response_body)
        return resource if resource.is_a?(FHIR::QuestionnaireResponse)
        return nil unless resource.is_a?(FHIR::Parameters)

        resource.parameter.find do |param|
          param.name == 'return' && param.resource.is_a?(FHIR::QuestionnaireResponse)
        end&.resource
      rescue JSON::ParserError
        nil
      end

      #########################################################################
      # Identify Adaptive Questionnaire Details
      #########################################################################

      def next_question_base_url(questionnaire, fhir_base_url)
        questionnaire_url = questionnaire.extension.find do |ext|
          ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive' &&
            ext.valueUrl.present?
        end&.valueUrl

        questionnaire_url.present? ? questionnaire_url : fhir_base_url
      end

      def extract_adaptive_questionnaires(package_bundles, questionnaire_response_templates)
        package_bundles.select { |bundle| bundle.entry.any? { |entry| adaptive_questionnaire?(entry.resource) } }
          .filter_map do |bundle|
            collect_adaptive_questionnaire_details(bundle, questionnaire_response_templates)
          end
      end

      def collect_adaptive_questionnaire_details(package_bundle, questionnaire_response_templates)
        questionnaire = package_bundle.entry.find { |entry| entry.resource.is_a?(FHIR::Questionnaire) }.resource
        canonical = canonical_url_for_resource(questionnaire)
        unless canonical.present?
          add_message('error', 'Adaptive Questionnaire has no canonical url, ' \
                               'cannot match to a QuestionnaireResponse template.')
          return nil
        end

        template = find_template_for_canonical(canonical, questionnaire_response_templates)
        unless template.present?
          add_message('error', 'No QuestionnaireResponse template provided for ' \
                               "Questionnaire with canonical `#{canonical}`.")
          return nil
        end

        questionnaire_response = package_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::QuestionnaireResponse)
        end&.resource
        unless questionnaire_response.present?
          questionnaire_response = template.dup
          questionnaire_response.item = []
        end

        { questionnaire:, questionnaire_response:, template: }
      end

      def find_template_for_canonical(canonical, questionnaire_response_templates)
        return nil unless questionnaire_response_templates.present?

        questionnaire_response_templates.find do |questionnaire_response|
          canonical == target_questionnaire_response_template_canonical(questionnaire_response)
        end
      end

      def target_questionnaire_response_template_canonical(questionnaire_response)
        questionnaire = extract_contained_questionnaire(questionnaire_response)
        return nil unless questionnaire.present?

        canonical_url_for_resource(questionnaire)
      end

      def extract_contained_questionnaire(questionnaire_response)
        questionnaire_response.contained.find { |entry| entry.is_a?(FHIR::Questionnaire) }
      end

      def canonical_url_for_resource(resource)
        return nil unless resource.url.present?

        "#{resource.url}#{"|#{resource.version}" if resource.version.present?}"
      end

      def adaptive_questionnaire?(resource)
        resource.is_a?(FHIR::Questionnaire) &&
          resource.extension.any? do |ext|
            ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive' &&
              (ext.valueBoolean || ext.valueUrl.present?)
          end
      end

      #########################################################################
      # Update QuestionnaireResponse for next $next-question request
      #########################################################################

      def new_answers?(new_items, template)
        return false unless template.item.present?

        template.item.any? do |item|
          new_items.include?(item.linkId) || new_answers?(new_items, item)
        end
      end

      def add_new_answers(questionnaire_response, new_items, template)
        new_items.each do |new_item|
          answer, parent_address = extract_template_answer_and_parent_address(new_item, template)
          next unless answer

          add_answer_under_address(questionnaire_response, answer, parent_address)
        end
        questionnaire_response
      end

      def extract_template_answer_and_parent_address(new_item, template)
        search_for_item(new_item, template.item, [])
      end

      def search_for_item(target_item, item_list, parent_address)
        item_list.each do |item_node|
          if item_node.linkId == target_item
            answer = item_node.dup
            answer.item = [] # don't add sub-answers
            return [answer, parent_address]
          elsif item_node.item.present?
            result = search_for_item(target_item, item_node.item, parent_address + [item_node.linkId])
            return result if result.present?
          end
        end
        nil
      end

      def add_answer_under_address(questionnaire_response, answer, address)
        item_node = questionnaire_response
        while address.present?
          next_link_id = address.shift
          item_node = item_node.item.find { |item| item.linkId == next_link_id }
          return unless item_node
        end
        item_node.item << answer
      end

      def identify_new_items(submitted_form, returned_form)
        original_questionnaire = extract_contained_questionnaire(submitted_form)
        updated_questionnaire = extract_contained_questionnaire(returned_form)
        return [] unless original_questionnaire.present? && updated_questionnaire.present?

        item_list(updated_questionnaire) - item_list(original_questionnaire)
      end

      def item_list(questionnaire)
        questionnaire.item.flat_map do |item|
          [item.linkId] + item_list(item)
        end.uniq.compact
      end

      def form_completed?(questionnaire_response)
        questionnaire_response.status == 'completed'
      end
    end
  end
end
