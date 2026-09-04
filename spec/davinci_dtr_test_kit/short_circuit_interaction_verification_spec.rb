require 'davinci_dtr_test_kit/full_ehr/short_circuit_interaction_verification'

RSpec.describe DaVinciDTRTestKit::ShortCircuitInteractionVerification do
  # described_class is a plain module (not an Inferno::DSL::Runnable), so the runnable spec
  # context isn't auto-included; pull in `run`, `test_session`, etc. explicitly.
  include_context 'when testing a runnable'

  let(:suite_id) { 'dtr_full_ehr_v220' }

  # A minimal Test that exercises check_for_short_circuit with custom messages, so the
  # scratch[:short_circuit] cases can be verified without depending on any real DTR test.
  let(:test_class) do
    Class.new(Inferno::Test) do
      include DaVinciDTRTestKit::ShortCircuitInteractionVerification

      id :short_circuit_verification_spec_test

      run do
        check_for_short_circuit(ok_message: 'custom ok message', bad_message: 'custom bad message')
        pass 'ran to completion'
      end
    end
  end

  # Same, but relies on the module's default messages.
  let(:default_message_test_class) do
    Class.new(Inferno::Test) do
      include DaVinciDTRTestKit::ShortCircuitInteractionVerification

      id :short_circuit_verification_default_message_spec_test

      run { check_for_short_circuit }
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    [test_class, default_message_test_class].each do |runnable|
      tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)
    end
  end

  describe '#check_for_short_circuit' do
    it 'does not affect the test when no flag is set in scratch' do
      result = run(test_class, {}, {})
      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('ran to completion')
    end

    it 'passes with the ok message when flagged :pass' do
      result = run(test_class, {}, { short_circuit: :pass })
      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('custom ok message')
    end

    it 'omits with the ok message when flagged :omit' do
      result = run(test_class, {}, { short_circuit: :omit })
      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('custom ok message')
    end

    it 'skips with the bad message when flagged :skip' do
      result = run(test_class, {}, { short_circuit: :skip })
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('custom bad message')
    end

    it 'fails with the bad message when flagged :fail' do
      result = run(test_class, {}, { short_circuit: :fail })
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('custom bad message')
    end

    it 'errors out on an unrecognized flag' do
      result = run(test_class, {}, { short_circuit: :bogus })
      expect(result.result).to eq('error')
      expect(result.result_message).to include('invalid short circuit action: bogus')
    end

    it 'falls back to the module default ok message when none is given' do
      result = run(default_message_test_class, {}, { short_circuit: :pass })
      expect(result.result_message)
        .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::DEFAULT_SHORT_CIRCUIT_OK_MESSAGE)
    end

    it 'falls back to the module default bad message when none is given' do
      result = run(default_message_test_class, {}, { short_circuit: :skip })
      expect(result.result_message)
        .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::DEFAULT_SHORT_CIRCUIT_BAD_MESSAGE)
    end
  end

  describe '#clear_short_circuit_flag' do
    let(:clearing_test_class) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ShortCircuitInteractionVerification

        id :short_circuit_verification_clear_spec_test

        run do
          clear_short_circuit_flag
          pass 'cleared'
        end
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(clearing_test_class) unless tests_repo.exists?(clearing_test_class.id.to_s)
    end

    it 'removes a previously set flag so it does not affect this test run' do
      scratch = { short_circuit: :skip }
      result = run(clearing_test_class, {}, scratch)

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('cleared')
      expect(scratch).to_not have_key(:short_circuit)
    end
  end

  describe '#short_circuit_validation_tests' do
    let(:setting_test_class) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ShortCircuitInteractionVerification

        id :short_circuit_verification_setting_spec_test

        run do
          short_circuit_validation_tests(:skip)
          pass 'flag set'
        end
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(setting_test_class) unless tests_repo.exists?(setting_test_class.id.to_s)
    end

    it 'stores the given action in scratch for downstream tests to see' do
      scratch = {}
      run(setting_test_class, {}, scratch)
      expect(scratch[:short_circuit]).to eq(:skip)
    end
  end

  describe '#check_for_adaptive_short_circuit' do
    let(:adaptive_test_class) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ShortCircuitInteractionVerification

        id :short_circuit_adaptive_verification_spec_test

        run do
          check_for_adaptive_short_circuit
          pass 'ran to completion'
        end
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(adaptive_test_class) unless tests_repo.exists?(adaptive_test_class.id.to_s)
    end

    it 'does not affect the test when no flag is set in scratch' do
      result = run(adaptive_test_class, {}, {})
      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('ran to completion')
    end

    it 'passes with the module message when scratch[:short_circuit_adaptive] is set' do
      result = run(adaptive_test_class, {}, { short_circuit_adaptive: :pass })
      expect(result.result).to eq('pass')
      expect(result.result_message)
        .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::SHORT_CIRCUIT_ADAPTIVE_MESSAGE)
    end

    it 'is unaffected by scratch[:short_circuit], which is a separate flag' do
      result = run(adaptive_test_class, {}, { short_circuit: :skip })
      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('ran to completion')
    end
  end

  describe '#clear_adaptive_short_circuit_flag' do
    let(:clearing_adaptive_test_class) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ShortCircuitInteractionVerification

        id :short_circuit_adaptive_verification_clear_spec_test

        run do
          clear_adaptive_short_circuit_flag
          pass 'cleared'
        end
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(clearing_adaptive_test_class) unless tests_repo.exists?(clearing_adaptive_test_class.id.to_s)
    end

    it 'removes a previously set flag so it does not affect this test run' do
      scratch = { short_circuit_adaptive: :pass }
      result = run(clearing_adaptive_test_class, {}, scratch)

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('cleared')
      expect(scratch).to_not have_key(:short_circuit_adaptive)
    end
  end

  describe '#short_circuit_adaptive_validation_tests' do
    let(:setting_adaptive_test_class) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ShortCircuitInteractionVerification

        id :short_circuit_adaptive_verification_setting_spec_test

        run do
          short_circuit_adaptive_validation_tests
          pass 'flag set'
        end
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(setting_adaptive_test_class) unless tests_repo.exists?(setting_adaptive_test_class.id.to_s)
    end

    it 'stores :pass in scratch[:short_circuit_adaptive] for downstream tests to see' do
      scratch = {}
      run(setting_adaptive_test_class, {}, scratch)
      expect(scratch[:short_circuit_adaptive]).to eq(:pass)
    end
  end
end
