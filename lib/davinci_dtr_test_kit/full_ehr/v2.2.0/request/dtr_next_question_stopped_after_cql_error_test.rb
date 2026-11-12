require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../short_circuit_interaction_verification'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionStoppedAfterCQLErrorTest < Inferno::Test
    include QuestionnaireHelper
    include ShortCircuitInteractionVerification

    id :dtr_full_ehr_v220_nq_stopped_after_cql_error
    title 'Client stops $next-question requests after receiving the CQL error'
    description %(
      During the interaction, one of Inferno's `$next-question` responses adds an item whose
      `calculatedExpression` is malformed CQL. A client that recognizes the problem must stop
      completing the form
      ([spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)),
      so it must not ask Inferno for further questions.

      This test finds the first `$next-question` response that returned the item containing the
      error and fails if the client made any `$next-question` request after it. It is skipped when
      the client never reached that item, because the client was then never exposed to the error.
    )

    DEFAULT_CQL_ERROR_LINK_ID = '3.3'.freeze

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    # linkId of the item carrying the malformed CQL in the scenario's $next-question template.
    def cql_error_link_id
      config.options[:cql_error_item_link_id].presence || DEFAULT_CQL_ERROR_LINK_ID
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])

      requests = load_tagged_requests(*target_tags).sort_by { |request| request.index.to_i }
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      error_response_index = requests.index { |request| response_returned_error_item?(request) }
      skip_if error_response_index.nil?,
              'No $next-question response returned the item containing the malformed CQL (linkId ' \
              "'#{cql_error_link_id}'), so the client was never exposed to the error. Answer the earlier " \
              'questions until Inferno returns that item.'

      later_request_count = requests.length - error_response_index - 1
      assert later_request_count.zero?,
             "The client made #{later_request_count} $next-question request(s) after Inferno returned the item " \
             "containing the malformed CQL (linkId '#{cql_error_link_id}') in $next-question response " \
             "#{error_response_index + 1}. Clients must stop requesting further questions once they detect " \
             'an error in the Questionnaire.'

      pass 'Inferno returned the item containing the malformed CQL in $next-question response ' \
           "#{error_response_index + 1} and the client made no further $next-question requests."
    end

    def response_returned_error_item?(request)
      return false unless request.status == 200

      questionnaire = contained_questionnaire_from_questionnaire_response(
        questionnaire_response_from_next_question_response(parsed_response(request))
      )
      return false if questionnaire.nil?

      nested_items(questionnaire.item).any? { |item| item.linkId == cql_error_link_id }
    end

    def parsed_response(request)
      FHIR.from_contents(request.response_body)
    rescue JSON::ParserError
      nil
    end

    def nested_items(items)
      Array.wrap(items).flat_map { |item| [item] + nested_items(item.item) }
    end
  end
end
