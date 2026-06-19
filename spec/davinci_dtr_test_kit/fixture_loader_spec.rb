require 'spec_helper'
require 'davinci_dtr_test_kit/full_ehr/fixture_loader'

RSpec.describe DaVinciDTRTestKit::FixtureLoader do
  subject(:loader) { described_class.instance }

  before do
    # Reset the Singleton cache between examples
    loader.instance_variable_set(:@cache, {})
  end

  describe '#[]' do
    context 'when path is blank' do
      it 'returns nil' do
        expect(loader[nil]).to be_nil
        expect(loader['']).to be_nil
      end
    end

    context 'when the fixture file exists and is valid JSON' do
      let(:path) { 'dinner_static/questionnaire_dinner_order_static.json' }

      it 'returns a FHIR resource' do
        result = loader[path]
        expect(result).to be_a(FHIR::Model)
      end

      it 'caches the result on subsequent calls' do
        first_call = loader[path]
        expect(File).to_not receive(:read)
        second_call = loader[path]
        expect(second_call).to equal(first_call)
      end
    end

    context 'when the fixture file does not exist' do
      it 'raises TestSuiteImplementationException with a descriptive message' do
        expect { loader['nonexistent/file.json'] }.to raise_error(
          Inferno::Exceptions::TestSuiteImplementationException,
          /File not found/
        )
      end
    end

    context 'when the fixture file contains invalid JSON' do
      before do
        allow(File).to receive(:read).and_return('not valid json {{{')
      end

      it 'raises TestSuiteImplementationException with a descriptive message' do
        expect { loader['dinner_static/questionnaire_dinner_order_static.json'] }.to raise_error(
          Inferno::Exceptions::TestSuiteImplementationException,
          /Invalid JSON in/
        )
      end
    end

    context 'when the fixture file contains valid JSON but not a FHIR resource' do
      before do
        allow(File).to receive(:read).and_return('{"foo": "bar"}')
      end

      it 'raises TestSuiteImplementationException with a descriptive message' do
        expect { loader['dinner_static/questionnaire_dinner_order_static.json'] }.to raise_error(
          Inferno::Exceptions::TestSuiteImplementationException,
          /does not contain a valid FHIR resource/
        )
      end
    end
  end
end
