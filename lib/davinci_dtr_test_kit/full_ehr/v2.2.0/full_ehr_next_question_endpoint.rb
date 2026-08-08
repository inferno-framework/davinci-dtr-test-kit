require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../../cross_suite/response_selection_utils'
require_relative '../fixture_loader'
require_relative '../../tags'
require_relative 'next_question_template_questionnaires'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRV220NextQuestionEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer
      include DaVinciDTRTestKit::FhirpathUtils
      include DaVinciDTRTestKit::ResponseSelectionUtils
      include DaVinciDTRTestKit::NextQuestionTemplateQuestionnaires

      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def tags
        tags = [CLIENT_NEXT_TAG]
        tags << test.config.options[:dtr_workflow_tag] if test.config.options[:dtr_workflow_tag].present?
        unless test.config.options[:dtr_exclude_from_questionnaire_must_support]
          tags << CLIENT_QUESTIONNAIRE_MUST_SUPPORT
        end

        tags
      end

      def make_response
        response.headers['Access-Control-Allow-Origin'] = '*'
        return if response.status == 401 # response set in update_result (expired token handling there)

        response.format = 'application/fhir+json'
        response.body = response_body.to_json
        response.status = if response_body.is_a?(FHIR::OperationOutcome)
                            400
                          else
                            200
                          end
      rescue StandardError => e
        Inferno::Application['logger'].error("Error responding to $next-question:\n#{e.full_message}")
        response.body =
          operation_outcome(
            'fatal',
            'processing',
            e.message
          ).to_json
        response.status = 500
      end

      def update_result
        return unless UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)

        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
      end

      private

      # ***********************************************************************
      # Response Body
      # ***********************************************************************

      def response_body
        @response_body ||= build_response_body
      end

      def build_response_body
        error_outcome = check_request_questionnaire_response_validity
        if error_outcome.is_a?(FHIR::OperationOutcome)
          error_outcome
        elsif questionnaire_template.is_a?(FHIR::OperationOutcome)
          questionnaire_template
        else
          update_response
        end
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      # ***********************************************************************
      # Request Details
      # ***********************************************************************

      def request_questionnaire_response
        @request_questionnaire_response ||= extract_questionnaire_response
      end

      def extract_questionnaire_response
        parsed_request_body = parse_fhir_object(request.body.string)
        if parsed_request_body.is_a?(FHIR::Parameters)
          questionnaire_response_param = find_questionnaire_response(parsed_request_body)
          return questionnaire_response_param if questionnaire_response_param.is_a?(FHIR::OperationOutcome)

          questionnaire_response = questionnaire_response_param.resource
          unless questionnaire_response.is_a?(FHIR::QuestionnaireResponse)
            return operation_outcome(
              'error',
              'business-rule',
              'Input `parameter:questionnaire-response.resource` is not a QuestionnaireResponse.'
            )
          end

          questionnaire_response
        elsif parsed_request_body.is_a?(FHIR::QuestionnaireResponse)
          parsed_request_body
        else
          operation_outcome('error', 'invalid',
                            'Wrong resource type submitted for $next-question request: ' \
                            "expected Parameters or QuestionnaireResponse, got #{parsed_request_body.resourceType}")
        end
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      def request_questionnaire
        @request_questionnaire ||= extract_contained_questionnaire
      end

      def extract_contained_questionnaire
        contained_questionnaire = request_questionnaire_response.contained&.find do |contained_resource|
          contained_resource.is_a?(FHIR::Questionnaire)
        end

        unless contained_questionnaire.present?
          return operation_outcome('error', 'invalid',
                                   'Invalid QuestionnaireResponse for $next-question request: ' \
                                   'no contained Questionnaire resource.')
        end
        unless contained_questionnaire.url.present?
          return operation_outcome('error', 'invalid',
                                   'Invalid QuestionnaireResponse for $next-question request: ' \
                                   'contained Questionnaire must have a url.')
        end

        contained_questionnaire
      end

      # ***********************************************************************
      # Verify Request
      # ***********************************************************************

      def check_request_questionnaire_response_validity
        return request_questionnaire_response if request_questionnaire_response.is_a?(FHIR::OperationOutcome)
        return request_questionnaire if request_questionnaire.is_a?(FHIR::OperationOutcome)

        target_questionnaire_canonical = questionnaire_canonical_url(request_questionnaire)
        packaged_questionnaire = requested_questionnaire(target_questionnaire_canonical)
        unless packaged_questionnaire.present?
          return operation_outcome('error', 'invalid',
                                   'Invalid QuestionnaireResponse for $next-question request: ' \
                                   "questionnaire #{target_questionnaire_canonical} not returned " \
                                   'by $questionnaire-package during this wait test.')
        end
        unless adaptive_questionnaire?(packaged_questionnaire)
          return operation_outcome('error', 'invalid',
                                   'Invalid QuestionnaireResponse for $next-question request: ' \
                                   "questionnaire #{target_questionnaire_canonical} is not adaptive.")
        end

        nil
      end

      def requested_questionnaire(questionnaire_canonical)
        successful_questionnaire_package_requests.each do |qp_request|
          response_parameters = FHIR.from_contents(qp_request.response_body)
          next unless response_parameters.present?

          response_parameters.parameter.select { |param| param.name == 'packagebundle' }.map(&:resource)
            .each do |bundle|
              target_questionnaire = extract_target_questionnaire(bundle, questionnaire_canonical)
              return target_questionnaire if target_questionnaire.present?
            end
        end
        nil
      end

      def successful_questionnaire_package_requests
        requests_repo = Inferno::Repositories::Requests.new
        previous_requests = requests_repo.requests_for_result(result.id)
        previous_requests.select { |req| req.url.include?('$questionnaire-package') && req.status == 200 }
          .map { |req| requests_repo.find_full_request(req.id) }
      end

      def extract_target_questionnaire(bundle, target_questionnaire_canonical)
        bundle.entry.each do |entry|
          next unless entry.resource.is_a?(FHIR::Questionnaire) &&
                      questionnaire_canonical_url(entry.resource) == target_questionnaire_canonical

          return entry.resource
        end
        nil
      end

      def questionnaire_canonical_url(questionnaire)
        if questionnaire.version.present?
          "#{questionnaire.url}|#{questionnaire.version}"
        else
          questionnaire.url
        end
      end

      def adaptive_questionnaire?(questionnaire)
        questionnaire.extension.any? do |ext|
          ext.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive' &&
            ((ext.valueBoolean == true) || ext.valueUri.present?)
        end
      end

      # ***********************************************************************
      # Response Template
      # ***********************************************************************

      def questionnaire_template
        @questionnaire_template ||=
          if template_from_fixture?
            questionnaire_template_from_fixture
          elsif template_from_input?
            questionnaire_template_from_input
          else
            raise Inferno::Exceptions::TestSuiteImplementationException.new(
              'dtr $next-question response template',
              'No response template source indicated by the test implementer, please file a bug report.'
            )
          end
      end

      def template_from_fixture?
        test.config.options[:nq_questionnaire_template_fixture].present?
      end

      def template_from_input?
        !template_from_fixture? && test.config.options[:nq_questionnaire_template_input].present?
      end

      def questionnaire_template_from_fixture
        fixture = FixtureLoader.instance[test.config.options[:nq_questionnaire_template_fixture]]
        unless fixture.is_a?(FHIR::Questionnaire)
          raise Inferno::Exceptions::TestSuiteImplementationException.new(
            'dtr $next-question response template fixture',
            'Invalid $next-question response template fixture: ' \
            "Expected Questionnaire, got '#{fixture.resourceType}'."
          )
        end
        fixture
      end

      def questionnaire_template_from_input
        input_name = test.config.options[:nq_questionnaire_template_input]
        value = JSON.parse(result.input_json)
          .find { |input| input['name'] == input_name }
          &.dig('value')

        title = input_title(input_name)
        unless value.present?
          return operation_outcome('error', 'invalid',
                                   "No response template provided by the user in input '#{title}'.")
        end

        parse_questionnaire_response_input_template(value, title)
      end

      def parse_questionnaire_response_input_template(value, title)
        parsed_json = JSON.parse(value)
        if parsed_json.is_a?(Array)
          matching_questionnaire_template(questionnaires_from_template_value(value), title)
        else
          parse_single_questionnaire_template(value, title)
        end
      rescue JSON::ParserError
        operation_outcome('error', 'invalid', "Input #{title} does not contain valid JSON.")
      end

      def parse_single_questionnaire_template(value, title)
        parsed = parse_fhir_object(value, entity: "Input #{title}")
        unless parsed.is_a?(FHIR::Questionnaire)
          return operation_outcome('error', 'invalid',
                                   'Invalid input response template for $next-question: ' \
                                   "Expected Questionnaire, got '#{parsed.resourceType}'.")
        end
        parsed
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      def matching_questionnaire_template(questionnaires, title)
        matching = questionnaires.find { |questionnaire| questionnaire_template_matches_request?(questionnaire) }
        return matching if matching.present?

        operation_outcome('error', 'invalid',
                          'Invalid input response template for $next-question: ' \
                          "No Questionnaire in input '#{title}' matches " \
                          "#{questionnaire_canonical_url(request_questionnaire)}.")
      end

      # test.config.options input references are stored as input names; testers only see the
      # input's title in the Inferno UI, so client-facing messages should use that instead.
      def input_title(input_name)
        test.config.input(input_name.to_sym)&.title || input_name
      end

      def questionnaire_template_matches_request?(questionnaire)
        return false unless questionnaire.url == request_questionnaire.url

        request_questionnaire.version.blank? || questionnaire.version == request_questionnaire.version
      end

      # ***********************************************************************
      # Replace {{fhirpath}} tokens in template
      # ***********************************************************************

      def replace_tokens_in_item(item)
        instantiated_json = replace_tokens_in_string(item.to_json, request_questionnaire_response)
        FHIR::Questionnaire::Item.new(JSON.parse(instantiated_json))
      rescue JSON::ParserError => e
        if template_from_fixture?
          raise Inferno::Exceptions::TestSuiteImplementationException.new('dtr response template tokens', e.message)
        end

        raise MockPayer::ParseError, e.message
      end

      # ***********************************************************************
      # Update Response
      # ***********************************************************************

      def update_response
        @new_questions_added = false
        add_questions_from_questionnaire_template
        complete_questionnaire_response if !@new_questions_added && questionnaire_response_completed?
        request_questionnaire_response
      rescue FhirpathServiceError => e
        raise if template_from_fixture?

        operation_outcome('error', 'invalid', e.message)
      end

      # ***********************************************************************
      # Add Question Items from Template
      # ***********************************************************************

      def add_questions_from_questionnaire_template
        questionnaire_template.item.each do |template_item|
          add_new_item_if_needed(template_item, request_questionnaire.item)
        end
      end

      def add_new_item_if_needed(item, target_list)
        existing = target_list.find { |target_item| item.linkId == target_item.linkId }
        return add_children_if_needed(item, existing) if existing
        return unless add_missing_item_to_response?(item)

        new_item = replace_tokens_in_item(item)
        strip_inferno_extensions(new_item)
        new_item.item = []
        target_list << new_item
        @new_questions_added = true
        add_children_if_needed(item, new_item)
      end

      def add_children_if_needed(template_item, form_item)
        return unless template_item.item.present?

        template_item.item.each { |child| add_new_item_if_needed(child, form_item.item) }
      end

      def add_missing_item_to_response?(item)
        return false if item.linkId.blank?

        include_entity?(item, request_questionnaire_response, '$next-question')
      end

      # ***********************************************************************
      # Complete QuestionnaireResponse
      # ***********************************************************************

      def questionnaire_response_completed?
        request_questionnaire.item.all? do |item|
          item_not_required_or_completed?(item, request_questionnaire_response.item)
        end
      end

      def item_not_required_or_completed?(item, response_item_list)
        required = (item.required == true)
        response_item = response_item_list.find { |response_item| response_item.linkId == item.linkId }
        not_required_or_completed = !required || answer_completed_and_valid?(item, response_item)
        return false unless not_required_or_completed

        item.item.all? { |sub_item| item_not_required_or_completed?(sub_item, response_item&.item || []) }
      end

      def answer_completed_and_valid?(_item, response_item)
        response_item&.answer&.any? { |answer| !answer&.value.nil? }
      end

      def complete_questionnaire_response
        request_questionnaire_response.status = 'completed'
      end
    end
  end
end
