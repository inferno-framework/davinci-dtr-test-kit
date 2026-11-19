require_relative '../../../urls'
require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220LogQuestionnaireErrorsRequestValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_log_errors_request_validation
    title '$log-questionnaire-errors request is valid'
    description %(
      The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-78)
      that a DTR client report malformed CQL to the payer using the
      [`$log-questionnaire-errors`](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html)
      operation, which DTR applications
      [SHALL support](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-1).

      During this test, Inferno verifies that each `$log-questionnaire-errors` request was sent to
      Inferno's `$log-questionnaire-errors` endpoint with a Parameters resource that conforms to the
      [DTR Log Questionnaire Errors Input Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-log-errors-input-parameters.html)
      profile, which requires a `questionnaire` canonical and an `operationOutcome` resource, and
      that the canonical identifies the Questionnaire Inferno returned during the interaction. The
      canonical
      [SHOULD be version-specific](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-3),
      so a canonical without a version produces a warning rather than a failure.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-1',
                          'hl7.fhir.us.davinci-dtr_2.2.0@oper-3',
                          'hl7.fhir.us.davinci-dtr_2.2.0@spec-78'

    LOG_ERRORS_INPUT_PROFILE =
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-log-errors-input-parameters|2.2.0'.freeze

    def target_tags
      tags = [CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def questionnaire_package_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    # Canonicals (url or url|version) of the Questionnaires Inferno returned during this
    # interaction, which the logged errors are expected to reference.
    def returned_questionnaire_canonicals
      @returned_questionnaire_canonicals ||=
        questionnaires_from_operation_responses(load_tagged_requests(*questionnaire_package_tags))
          .map { |questionnaire| questionnaire_canonical_url(questionnaire) }
          .uniq
    end

    run do
      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A $log-questionnaire-errors request must be made prior to running this test'

      requests.each_with_index do |log_request, request_index|
        unless log_request.url == log_questionnaire_errors_url
          add_request_message(
            'error',
            "Request made to wrong URL: #{log_request.url}. Should instead be to #{log_questionnaire_errors_url}.",
            request_index
          )
        end

        input_params = parse_fhir_request_entity(log_request.request_body, 'Request', request_index)
        unless input_params.present?
          add_request_message('error', 'Request does not contain a recognized FHIR resource', request_index)
          next
        end
        unless input_params.is_a?(FHIR::Parameters)
          add_request_message('error', 'Request is not FHIR Parameters resource', request_index)
          next
        end

        resource_is_valid?(resource: input_params,
                           profile_url: LOG_ERRORS_INPUT_PROFILE,
                           message_prefix: request_prefix(request_index))

        check_logged_questionnaire_canonicals(input_params, request_index)
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $log-questionnaire-errors request(s). See Messages for details."
      )
    end

    # The profile requires the `questionnaire` parameter, so a missing one is reported by the
    # validator. This checks that each canonical names a Questionnaire Inferno actually returned.
    def check_logged_questionnaire_canonicals(params, request_index)
      return if returned_questionnaire_canonicals.empty?

      params.parameter.select { |param| param.name == 'questionnaire' }.filter_map(&:valueCanonical)
        .each { |canonical| check_logged_questionnaire_canonical(canonical, request_index) }
    end

    # The url must be one Inferno returned and, when the canonical has a version, so must the
    # version. A canonical without a version is only warned about (oper-3 is a SHOULD), and only
    # when Inferno returned the Questionnaire with a version the client could have used.
    def check_logged_questionnaire_canonical(canonical, request_index)
      url, version = canonical.split('|', 2)
      returned = returned_questionnaire_canonicals.select { |candidate| candidate.split('|', 2).first == url }

      if returned.empty? || (version.present? && returned.exclude?(canonical))
        add_request_message(
          'error',
          "Questionnaire canonical #{canonical} does not identify a Questionnaire returned by Inferno " \
          "during this interaction (#{returned_questionnaire_canonicals.join(', ')}).",
          request_index
        )
      elsif version.blank? && versioned?(returned)
        add_request_message(
          'warning',
          "Questionnaire canonical #{canonical} is not version-specific. " \
          "The reference SHOULD include the version of the Questionnaire (#{returned.join(', ')}).",
          request_index
        )
      end
    end

    def versioned?(canonicals)
      canonicals.any? { |canonical| canonical.include?('|') }
    end
  end
end
