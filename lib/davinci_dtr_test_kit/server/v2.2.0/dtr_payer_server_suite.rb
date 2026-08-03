require 'smart_app_launch_test_kit'
require_relative 'interaction_test'
require_relative 'questionnaire_package_support/questionnaire_response_validation_test'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRPayerServerSuiteV220 < Inferno::TestSuite
      id :dtr_payer_server_v220
      title 'Da Vinci Payer Server Test Suite v2.2.0'
      description File.read(File.join(__dir__, 'dtr_payer_server_suite_description_v220.md'))

      links [
        {
          label: 'Report Issue',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/issues'
        },
        {
          label: 'Open Source',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit'
        },
        {
          label: 'Download',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/releases'
        },
        {
          label: 'Implementation Guide',
          url: 'https://hl7.org/fhir/us/davinci-dtr/2.2.0/'
        }
      ]

      requirement_sets(
        {
          identifier: 'hl7.fhir.us.davinci-dtr_2.2.0',
          title: 'Da Vinci Documentation Templates and Rules (DTR) v2.2.0',
          actor: 'Payer Service'
        }
      )

      fhir_resource_validator do
        igs('hl7.fhir.us.davinci-dtr#2.2.0')

        exclude_message do |message|
          message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
        end
      end

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'

      group do
        title 'Discovery'

        # TODO
        # conf-1 - CS matches CS in the IG
      end

      group from: :'smart_stu2-smart_backend_services' do
        # TODO
        # spec-120 [QUESTIONABLE]- payers require clients to use backend services
      end

      group do
        id :dtr_payer_server_v220_questionnaires
        title 'Questionnaire Operations'
        run_as_group

        input :backend_services_smart_auth_info,
              title: 'OAuth Credentials',
              type: :auth_info,
              optional: true

        fhir_client do
          url :url
          auth_info :backend_services_smart_auth_info
        end

        group do
          title 'Questionnaire Interactions'

          group do
            title 'Interactions'
            # TODO: make #questionnaire_interaction identify static/adaptive questionnaires
            test from: :dtr_v220_payer_interaction
          end

          group do
            title 'Request Validation'
            simulation_verification
          end
        end

        group do
          title 'Questionnaire/$questionnaire-package Support'

          # TODO: verify that each of these parameter types is used
          # One with questionnaire url
          # One with CRD/PAS context ID
          # Request/Encounter resource

          # TODO: base response validation
          # oper-10 - verify response conforms to profile [DONE]
          # oper-12 - [NOT TESTED in 2.0] include Questionnaire as 1st entry, [TESTED] and CQL libraries
          # oper-14 - [NOT TESTED in 2.0] Bundle includes all VS instances
          # oper-16 - [NOT TESTED in 2.0] references are version specific
          # sec-4 - no hidden read-only questions
          test from: :dtr_v220_payer_questionnaire_response_validation

          # TODO: embedded QR validation
          # spec-25 - [NOT TESTED in 2.0] QR has contained Q
          # spec-122 - [NOT TESTED in 2.0] QR.Q points to canonical of the Q provided
          # spec-139 - All references in QR are to contained or client resources
          # spec-141 - contained resources only in item.answer
        end

        group do
          title 'Questionnaire/$next-question support'
          optional
          # TODO
          # spec-23 - adaptive form validation [DONE]
          # spec-24 - [NOT TESTED in 2.0] url shall be a sub-url, accessed using same credentials

          # TODO
          # sec-4 - no hidden read-only questions

          # TODO
          # spec-39 - [QUESTIONABLE] display item indicating Q completion included at end
        end

        group do
          title 'Questionnaire design'

          # TODO
          # spec-17 - verify that Questionnaires use enableWhen/enableWhenExpression
          # spec-18 - verify CQL is used for expressions [DONE]
          # spec-54 - Qs include population logic [DONE]

          # TODO
          # spec-93 - [NOT TESTED in 2.0] CQL has context of "Patient"
          # spec-94 - [NOT TESTED in 2.0] CQL follows SDC rules for determining context

          # TODO
          # spec-87 - libraries are referenced with cqf-library extension and included [DONE]
          # spec-98 - Library names shall be unique within a Q package [DONE]
          # spec-95 - CQL and ELM are provided in libraries [DONE]
          # spec-99 - Libraries send CQL and ELM in content.data [DONE]
          # oper-13 - Libraries include both CQL and EML representations [DONE]
          # spec-96 - [NOT TESTED in 2.0] CQL and ELM are provided in expressions
          # spec-97 [QUESTIONABLE] - [NOT TESTED in 2.0] variables reference library if multiple libraries are used

          # TODO
          # spec-160 - contained binary resources shall be pdfs or xhtml
          # spec-165 [QUESTIONABLE]- contained binary page reference validation
        end

        group do
          title 'ValueSet/$expand Support'
          # [NOT TESTED]

          # TODO
          # oper-5 - VS shall use current date and only include active codes

          # TODO
          # oper-15 - [NOT TESTED in 2.0] VS with <40 entries SHALL be expanded
        end
      end

      group do
        title 'Log Questionnaire Error Support'
        # TODO
        # (optionally ?) perform $q-p operation and validate input

        # TODO
        # oper-1 - shall support it
      end

      group do
        title 'Error Handling'

        # TODO
        # oper-9 - make a request with a known bad questionnaire url

        # TODO
        # spec-130 - 4xx w/OO for issues with source data

        # TODO
        # spec-147 - 400 w/OO for invalid QR
      end
    end
  end
end
