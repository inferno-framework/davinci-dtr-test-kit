module DaVinciDTRTestKit
  module ShortCircuitInteractionVerification
    def clear_short_circuit_flag
      scratch.delete(:short_circuit)
    end

    def short_circuit_validation_tests(action)
      scratch[:short_circuit] = action
    end

    def check_for_short_circuit(ok_message: '', bad_message: '')
      return unless scratch[:short_circuit].present?

      case scratch[:short_circuit]
      when :pass
        short_circuit_pass(message: ok_message)
      when :omit
        short_circuit_omit(message: ok_message)
      when :skip
        short_circuit_skip(message: bad_message)
      when :fail
        short_circuit_fail(message: bad_message)
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'ShortCircuitInteractionVerification',
          "invalid short circuit action: #{scratch[:short_circuit]}"
        )
      end
    end

    DEFAULT_SHORT_CIRCUIT_OK_MESSAGE = 'No Questionnaires need to be completed.'.freeze

    def short_circuit_pass(message: '')
      message = DEFAULT_SHORT_CIRCUIT_OK_MESSAGE unless message.present?
      pass message
    end

    def short_circuit_omit(message: '')
      message = DEFAULT_SHORT_CIRCUIT_OK_MESSAGE unless message.present?
      omit message
    end

    DEFAULT_SHORT_CIRCUIT_BAD_MESSAGE = 'Failed to setup the Inferno DTR payer server simulation.'.freeze

    def short_circuit_skip(message: '')
      message = DEFAULT_SHORT_CIRCUIT_BAD_MESSAGE unless message.present?
      skip message
    end

    def short_circuit_fail(message: '')
      message = DEFAULT_SHORT_CIRCUIT_BAD_MESSAGE unless message.present?
      assert false, message
    end
  end
end
