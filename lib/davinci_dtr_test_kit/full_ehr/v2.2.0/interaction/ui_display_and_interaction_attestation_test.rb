require 'securerandom'
require_relative '../../../urls'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220UIDisplayAndInteractionAttestationTest < Inferno::Test
    include URLs
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_ui_display_and_interaction
    title 'Client correctly displays and allows users to interact with the questionnaire(s)'
    description %(
      During this test, the tester will confirm that during the previous interaction
      the client system was able to fully support the completion of the Questionnaires
      returned by Inferno's simulated DTR payer server. Most details showing that the client
      conformed to the DTR specification in its support for Questionnaires are not visible
      to Inferno, so it is the responsibility of the tester to confirm that the Questionnaires
      were faithfully computed, displayed, and saved per the DTR requirements.

      Notable requirements that testers are expected to demonstrate and attest client conformance to
      include:
      - The ability to calculate, render, and allow users to fill out forms specified as Questionnaires as
        directed by the Questionnaire's elements and extensions: Completing Questionnaires is a visual task
        and DTR and the underlying Structured Data Capture specification contain many details about directives
        that control the behavior of Questionnaires while users are completing them. Clients are required to
        support the behavior of the Questionnaire items and extensions listed as must support, and they are
        required to support or gracefully ignore non-must support items and extensions present on the differential
        tabs of DTR Questionnaire profiles ([base](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-base-questionnaire.html),
        [standard](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-std-questionnaire.html),
        and [adaptive](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaire-adapt.html)).
        By attesting **true** during this test, the tester confirms that each of the must support or differential
        items observed within the Questionnaires returned during the previous interaction were exercised and
        appropriately supported by the client and resulted in the correct behavior (or were ignored if allowed).
      - The ability to complete standard Questionnaires: unlike adaptive Questionnaires, where Inferno
        acting as the payer sees the QuestionnaireResponse on $next-question requests and determines
        whether it is complete, Inferno has no access to QuestionnaireResponses for standard Questionnaires.
        By attesting **true** during this test, the tester confirms that each unique Questionnaire returned
        by Inferno during the previous interaction, including the standard Questionnaires, was completed at least once.
      - The ability to store completed forms for use as a QuestionnaireResponse: Completed forms are generally
        intended to be communicated to downstream systems for particularly uses, but DTR does not specify an
        access mechanism or required communication API. Thus, Inferno does not have a way to see and confirm
        that completed forms have been stored appropriately and made avaialble as QuestionnaireResponses. By
        attesting **true** during this test, tester confirm that all completed Questionnaires were stored
        in such a way as to allow downstream communication as QuestionnaireResponses.

      To assist testers in making these determinations, the attestation dialog will include
      - The list of unique Questionnaires returned during the previous interaction so that testers
        can confirm that each unique Questionnaires was completed at least once and all completed forms were stored.
      - The list of Questionnaire must support elements and extensions observed within the Questionnaires
        returned during the previous interaction along with links to descriptions of them so that testers
        can confirm that they were exercised, appropriately supported, and drove the correct form behavior.
      - The list of Questionnaire non-must support differential elements and extensions observed within the
        Questionnaires returned during the previous interaction along with links to descriptions of them so
        that testers can confirm that they were exercised, appropriately supported, and drove the correct form behavior
        or were gracefully ignored without hindering completion of the form.
    )

    output :attest_true_url
    output :attest_false_url

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def requests_to_analyze
      @requests_to_analyze ||= load_tagged_requests(*target_tags)
    end

    def returned_questionnaires_for_display
      requests_to_analyze.each_with_object([]) do |request, questionnaires|
        request_parameters = FHIR.from_contents(request.response_body)
        next unless request_parameters.is_a?(FHIR::Parameters)

        questionnaires.concat(
          questionnaires_from_questionnaire_package_output_parameters(request_parameters)
            .map { |questionnaire| questionnaire_display(questionnaire) }
        )
      rescue JSON::ParserError
        next
      end.uniq
    end

    LIST_ENTRY_PREFIX = "\n          - ".freeze

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])
      skip_if no_questionnaires_returned?(requests_to_analyze),
              'No Questionnaire Package requests returned a Questionnaire.'

      identifier = SecureRandom.hex(32)
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_true_url:)
      output(attest_false_url:)

      wait(
        identifier: identifier,
        message: %(
          I attest that the DTR client application supported the completion
          of all unique Questionnaires returned by Inferno in response to client requests
          during the previous interaction, including
          - Rendering, pre-populating answers, and allowing users to fill out the form as
            indicated by the items and directives in the Questionnaires (see list of
            observed items and extensions below).
          - Storage of each completed Questionnaires for later use as QuestionnaireResponses
            (see list of returned Questionnaires below).

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.

          -------------

          Questionnaires returned during the previous interaction for which a
          response must have been completed and stored to attest **true**:
          - #{returned_questionnaires_for_display.join(LIST_ENTRY_PREFIX)}

          Must Support Questionnaire items and extensions that must have been followed
          to attest **true**: TODO

          Additional Questionnaire items and extensions that must have been followed or
          gracefully ignored to attest **true**: TODO
        )
      )
    end
  end
end
