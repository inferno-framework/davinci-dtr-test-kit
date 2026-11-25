require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionStoppedAfterCQLErrorTest < Inferno::Test
    include QuestionnaireHelper

    # linkId of the item carrying the malformed calculatedExpression in
    # fixtures/cql_error/cql_error_next_question_template.json.
    CQL_ERROR_ITEM_LINK_ID = '2'.freeze

    id :dtr_full_ehr_v220_nq_stopped_after_cql_error
    title 'Client stops $next-question requests after receiving the CQL error'
    description %(
      The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)
      that, when malformed CQL in questionnaire logic means the form can't be completed reliably, the
      client notify the user and prohibit further completion of the form.

      During this test, Inferno verifies that the client made no `$next-question` request after the
      `$next-question` response that returned the item with the malformed CQL. The test is skipped if
      no response returned that item.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-81'

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      requests = load_tagged_requests(*target_tags).sort_by { |request| request.index.to_i }
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      error_response_index = requests.index { |request| response_returned_error_item?(request) }
      skip_if error_response_index.nil?,
              'No $next-question response returned the item containing the malformed CQL (linkId ' \
              "'#{CQL_ERROR_ITEM_LINK_ID}'), so the client was never exposed to the error. Answer the first " \
              'question so that Inferno returns that item.'

      later_request_count = requests.length - error_response_index - 1
      assert later_request_count.zero?,
             "The client made #{later_request_count} $next-question request(s) after Inferno returned the item " \
             "containing the malformed CQL (linkId '#{CQL_ERROR_ITEM_LINK_ID}') in $next-question response " \
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

      nested_items(questionnaire.item).any? { |item| item.linkId == CQL_ERROR_ITEM_LINK_ID }
    end

    def parsed_response(request)
      return nil if request.response_body.blank?

      FHIR.from_contents(request.response_body)
    rescue JSON::ParserError
      nil
    end

    def nested_items(items)
      Array.wrap(items).flat_map { |item| [item] + nested_items(item.item) }
    end
  end
end
