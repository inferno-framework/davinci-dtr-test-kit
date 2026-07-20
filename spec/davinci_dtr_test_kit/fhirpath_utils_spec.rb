require 'spec_helper'
require 'davinci_dtr_test_kit/cross_suite/fhirpath_utils'

RSpec.describe DaVinciDTRTestKit::FhirpathUtils do
  subject(:host) { Class.new { include DaVinciDTRTestKit::FhirpathUtils }.new }

  let(:evaluator) { instance_double(Inferno::DSL::FhirpathEvaluation::Evaluator) }

  before do
    allow(host).to receive(:fhirpath_evaluator).and_return(evaluator)
  end

  def fhirpath_response(status:, body:)
    instance_double(Faraday::Response, status:, body:)
  end

  describe '#execute_fhirpath' do
    it 'returns the service result when the status is 2xx' do
      response = fhirpath_response(status: 200, body: '[{"type":"boolean","element":true}]')
      allow(evaluator).to receive(:call_fhirpath_service).with('body', 'query').and_return(response)

      expect(host.execute_fhirpath('body', 'query')).to eq(response)
    end

    it 'raises FhirpathServiceError when the status is non-2xx' do
      response = fhirpath_response(status: 500, body: 'Internal Server Error')
      allow(evaluator).to receive(:call_fhirpath_service).and_return(response)

      expect { host.execute_fhirpath('body', 'query') }
        .to raise_error(DaVinciDTRTestKit::FhirpathUtils::FhirpathServiceError)
    end

    it 'includes the status, query, and response body in the error message' do
      response = fhirpath_response(status: 422, body: 'Unprocessable')
      allow(evaluator).to receive(:call_fhirpath_service).and_return(response)

      expect { host.execute_fhirpath('body', 'my.query') }
        .to raise_error(DaVinciDTRTestKit::FhirpathUtils::FhirpathServiceError, /422.*my\.query.*Unprocessable/m)
    end
  end

  describe '#interpret_fhirpath_result_as_boolean' do
    def result_with_body(body)
      instance_double(Faraday::Response, body:)
    end

    it 'returns false for an empty results array' do
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body('[]'))).to be false
    end

    it 'returns false when there is more than one result' do
      body = '[{"type":"boolean","element":true},{"type":"boolean","element":false}]'
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body(body))).to be false
    end

    it 'returns true when the single result is a boolean true element' do
      body = '[{"type":"boolean","element":true}]'
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body(body))).to be true
    end

    it 'returns false when the single result is a boolean false element' do
      body = '[{"type":"boolean","element":false}]'
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body(body))).to be false
    end

    it 'returns true for a single non-boolean result (any value present counts as truthy)' do
      body = '[{"type":"string","element":"some value"}]'
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body(body))).to be true
    end

    it 'returns false when the response body is not valid JSON' do
      expect(host.interpret_fhirpath_result_as_boolean(result_with_body('not json'))).to be false
    end
  end

  describe '#replace_tokens_in_string' do
    let(:request) { FHIR::Parameters.new }

    it 'returns the string unchanged when there are no {{ tokens' do
      expect(host.replace_tokens_in_string('no tokens here', request)).to eq('no tokens here')
    end

    it 'replaces a single token with the FHIRPath result' do
      allow(host).to receive(:calculate_expression_string_value).with(request, 'some.expr').and_return('replaced')
      expect(host.replace_tokens_in_string('prefix {{some.expr}} suffix', request))
        .to eq('prefix replaced suffix')
    end

    it 'replaces multiple distinct tokens independently' do
      allow(host).to receive(:calculate_expression_string_value).with(request, 'expr.a').and_return('A')
      allow(host).to receive(:calculate_expression_string_value).with(request, 'expr.b').and_return('B')
      expect(host.replace_tokens_in_string('{{expr.a}} and {{expr.b}}', request)).to eq('A and B')
    end

    it 'evaluates duplicate token expressions only once' do
      allow(host).to receive(:calculate_expression_string_value).with(request, 'expr').and_return('val')
      result = host.replace_tokens_in_string('{{expr}} then {{expr}}', request)
      expect(host).to have_received(:calculate_expression_string_value).with(request, 'expr').once
      expect(result).to eq('val then val')
    end
  end

  describe '#calculate_expression_string_value' do
    let(:request) { FHIR::Parameters.new }

    before do
      allow(host).to receive(:execute_fhirpath).and_return(fhirpath_response(status: 200, body: response_body))
    end

    context 'with scalar results' do
      let(:response_body) do
        [{ 'type' => 'string', 'element' => 'hello' }, { 'type' => 'integer', 'element' => 42 }].to_json
      end

      it 'joins scalar element values with a comma' do
        expect(host.calculate_expression_string_value(request, 'expr')).to eq('hello,42')
      end
    end

    context 'with complex (Hash) results' do
      let(:response_body) do
        [{ 'type' => 'FHIR.Coding', 'element' => { 'system' => 'http://example.com', 'code' => 'abc' } }].to_json
      end

      it 'filters out Hash elements and returns an empty string' do
        expect(host.calculate_expression_string_value(request, 'expr')).to eq('')
      end
    end

    context 'with Array elements' do
      let(:response_body) do
        [{ 'type' => 'FHIR.Extension', 'element' => ['a', 'b'] }].to_json
      end

      it 'filters out Array elements and returns an empty string' do
        expect(host.calculate_expression_string_value(request, 'expr')).to eq('')
      end
    end

    context 'with empty results' do
      let(:response_body) { '[]' }

      it 'returns an empty string' do
        expect(host.calculate_expression_string_value(request, 'expr')).to eq('')
      end
    end

    context 'with mixed scalar and complex results' do
      let(:response_body) do
        [
          { 'type' => 'string', 'element' => 'kept' },
          { 'type' => 'FHIR.Coding', 'element' => { 'code' => 'dropped' } }
        ].to_json
      end

      it 'includes only the scalar values' do
        expect(host.calculate_expression_string_value(request, 'expr')).to eq('kept')
      end
    end
  end
end
