module DaVinciDTRTestKit
  module MockPayer
    module FullEHRV220ValueSetHelper
      def value_sets_from_fixture?
        test.config.options[:value_set_bundle_fixture].present?
      end

      def value_sets_from_input?
        value_sets_from_fixture? && test.config.options[:value_set_bundle_input].present?
      end

      def value_set_bundle_from_fixture
        fixture = FixtureLoader.instance[test.config.options[:value_set_bundle_fixture]]
        unless fixture.is_a?(FHIR::Bundle)
          raise Inferno::Exceptions::TestSuiteImplementationException.new(
            'ValueSets Bundle fixture',
            'Invalid ValueSets Bundle fixture: ' \
            "Expected Bundle, got '#{fixture.resourceType}'."
          )
        end
        fixture
      end

      def value_set_bundle_from_input
        input_name = test.config.options[:value_set_bundle_input]
        value = JSON.parse(result.input_json)
          .find { |input| input['name'] == input_name }
          &.dig('value')

        title = input_title(input_name)
        unless value.present?
          return operation_outcome('error', 'invalid',
                                   "No response template provided by the user in input '#{title}'.")
        end

        parse_bundle_input_template(value, title)
      end

      def parse_bundle_input_template(value, title)
        parsed = parse_fhir_object(value, entity: "Input #{title}")
        unless parsed.is_a?(FHIR::Bundle)
          return operation_outcome('error', 'invalid',
                                   'Invalid input ValueSet Bundle: ' \
                                   "Expected Bundle, got '#{parsed.resourceType}'.")
        end
        parsed
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      # test.config.options input references are stored as input names; testers only see the
      # input's title in the Inferno UI, so client-facing messages should use that instead.
      def input_title(input_name)
        test.config.input(input_name.to_sym)&.title || input_name
      end
    end
  end
end
