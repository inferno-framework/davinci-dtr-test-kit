module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRPayerServerCapabilityStatementTest < Inferno::Test
      id :dtr_payer_server_v220_capability_statement_test

      title 'Server CapabilityStatement declares required DTR Payer Service operations'

      description %(
        The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#conformance-to-this-implementation-guide)
        conformant systems to conform to an appropriate CapabilityStatement. This test verifies that the payer server's
        CapabilityStatement declares support for the operations required by the DTR Payer Service CapabilityStatement.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-1'

      REQUIRED_RESOURCE_OPERATIONS = {
        'Questionnaire' => [
          'questionnaire-package',
          'next-question',
          'log-questionnaire-errors'
        ],
        'ValueSet' => ['expand']
      }.freeze

      run do
        fhir_get_capability_statement

        assert_response_status(200)
        assert_resource_type(:capability_statement)
        assert_valid_resource

        server_rest = resource.rest.find { |rest| rest.mode == 'server' }

        unless server_rest.present?
          add_message(
            'error',
            'CapabilityStatement is missing a `rest` entry with `mode` set to `server`.'
          )
        end

        if server_rest.present?
          REQUIRED_RESOURCE_OPERATIONS.each do |resource_type, required_operations|
            resource_entry = server_rest.resource.find do |entry|
              entry.type == resource_type
            end

            unless resource_entry.present?
              add_message(
                'error',
                "CapabilityStatement is missing a `#{resource_type}` resource entry " \
                'in its server-mode `rest` section.'
              )
              next
            end

            declared_operations = resource_entry.operation.map(&:name)
            missing_operations = required_operations - declared_operations

            next if missing_operations.empty?

            add_message(
              'error',
              "CapabilityStatement is missing required `#{resource_type}` operations: " \
              "#{missing_operations.map { |operation| "$#{operation}" }.join(', ')}."
            )
          end
        end

        assert_no_error_messages
      end
    end
  end
end
