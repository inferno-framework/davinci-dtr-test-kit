require 'time'
require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnairePackageChangedSinceTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper

    CLOCK_SKEW_SECONDS = 60
    INSTANT_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/

    id :dtr_full_ehr_v220_qp_changedsince
    title 'Resumed Questionnaire Package request includes a valid changedsince timestamp'
    description %(
      The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-questionnaire-package.html#ci-c-oper-20)
      that when resuming a work in progress QuestionnaireResponse, a DTR client invoke the
      $questionnaire-package operation with the `changedsince` timestamp.

      During this test, Inferno verifies that at least one $questionnaire-package request made after Inferno returned
      a Questionnaire package includes a `changedsince` parameter, and that each `changedsince` parameter
      - is an `instant` (a date and time with seconds and a time zone),
      - is not earlier than the time Inferno first returned a Questionnaire package during this scenario, and
      - is not later than the time of the request that carried it.

      Inferno does not see the saved QuestionnaireResponse, so it cannot compare the timestamp with
      `QuestionnaireResponse.meta.lastUpdated` directly. To allow for differences between the client's
      clock and Inferno's, both time comparisons accept timestamps up to
      #{CLOCK_SKEW_SECONDS} seconds outside the window.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-20'

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A Questionnaire Package request must be made prior to running this test'

      first_retrieval_time = requests.select { |request| package_returned?(request) }.map(&:created_at).min
      skip_if first_retrieval_time.blank?,
              'Inferno did not return a Questionnaire package, so there was no package retrieval to resume from.'

      resumed_requests = requests.each_with_index.filter_map do |request, index|
        changedsince = changedsince_parameter(request)
        [request, index, changedsince] if changedsince.present?
      end
      assert resumed_requests.present?,
             'No $questionnaire-package request included the `changedsince` parameter. When resuming a ' \
             'work in progress QuestionnaireResponse, the client SHALL invoke the operation with the ' \
             'timestamp of the last package retrieval.'

      resumed_requests.each do |request, index, changedsince|
        check_changedsince(changedsince, request, index, first_retrieval_time)
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Invalid `changedsince` parameter(s). See Messages for details."
      )
    end

    private

    def request_parameters(request)
      parsed = FHIR.from_contents(request.request_body)
      parsed if parsed.is_a?(FHIR::Parameters)
    rescue StandardError
      nil
    end

    def changedsince_parameter(request)
      request_parameters(request)&.parameter&.find { |param| param.name == 'changedsince' }
    end

    def package_returned?(request)
      return false if request.status != 200 || changedsince_parameter(request).present?

      response = FHIR.from_contents(request.response_body)
      response.is_a?(FHIR::Parameters) &&
        response.parameter.any? { |param| param.name == 'packagebundle' && param.resource.present? }
    rescue StandardError
      false
    end

    def check_changedsince(changedsince, request, index, first_retrieval_time)
      value = changedsince.valueInstant
      if value.blank?
        add_request_message('error', '`changedsince` must be provided as `valueInstant`.', index)
        return
      end

      timestamp = parse_instant(value)
      if timestamp.nil?
        add_request_message('error',
                            "`changedsince` value `#{value}` is not a valid instant " \
                            '(a date and time with seconds and a time zone).', index)
        return
      end

      check_timestamp_window(timestamp, value, request, index, first_retrieval_time)
    end

    def check_timestamp_window(timestamp, value, request, index, first_retrieval_time)
      if request.created_at < first_retrieval_time
        add_request_message('error',
                            'Request included `changedsince` but was made before Inferno first returned a ' \
                            "Questionnaire package at #{format_time(first_retrieval_time)}.", index)
      elsif timestamp < first_retrieval_time - CLOCK_SKEW_SECONDS
        add_request_message('error',
                            "`changedsince` value `#{value}` is earlier than the time Inferno first returned " \
                            "a Questionnaire package, #{format_time(first_retrieval_time)}.", index)
      end

      return unless timestamp > request.created_at + CLOCK_SKEW_SECONDS

      add_request_message('error',
                          "`changedsince` value `#{value}` is later than the time of the request, " \
                          "#{format_time(request.created_at)}.", index)
    end

    def parse_instant(value)
      return unless INSTANT_REGEX.match?(value)

      Time.iso8601(value)
    rescue ArgumentError
      nil
    end

    def format_time(time)
      time.getutc.iso8601
    end
  end
end
