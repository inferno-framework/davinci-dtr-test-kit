RSpec.describe DaVinciDTRTestKit::CQLTest, :runnable do
  let(:suite_id) { 'dtr_payer_server' }
  let(:url) { 'http://example.com/fhir' }
  let(:access_token) { 'dummy' }
  let(:retrieval_method) { 'Static' }
  let(:inputs) { { url:, access_token:, retrieval_method: } }
  
  context 'when output is valid' do
    let(:scratch) do
      output_params = FHIR.from_contents(File.read(File.join(__dir__, '..', 'fixtures',
                                                             'questionnaire_package_output_params_conformant.json')))
      { static_questionnaire_bundles: [output_params.parameter.first.resource] }
    end

    describe 'static questionnaire package libraries test' do
      let(:runnable) { find_test suite, 'static_form_libraries_test' }

      it 'passes if questionnaire package has libraries' do
        result = run(runnable, inputs, scratch)
        expect(result.result).to eq('pass'), result.result_message
      end
    end

    describe 'static questionnaire extensions check' do
      let(:runnable) { find_test suite, 'static_form_expressions_test' }

      it 'passes if questionnaire package has valid extensions' do
        result = run(runnable, inputs, scratch)
        expect(result.result).to eq('pass'), result.result_message
      end
    end
  end

  context 'when output is invalid' do
    let(:scratch) do
      output_params = FHIR.from_contents(
        File.read(File.join(__dir__, '..', 'fixtures',
                            'questionnaire_package_output_params_non_conformant.json'))
      )
      { static_questionnaire_bundles: [output_params.parameter.first.resource] }
    end

    describe 'static questionnaire package has no libraries test' do
      let(:runnable) { find_test suite, 'static_form_libraries_test' }

      it 'fails if questionnaire package has no libraries' do
        result = run(runnable, inputs, scratch)
        expect(result.result).to eq('fail'), result.result_message
      end
    end

    describe 'static questionnaire extensions check' do
      let(:runnable) { find_test suite, 'static_form_expressions_test' }

      it 'fails if questionnaire package has invalid extensions' do
        result = run(runnable, inputs, scratch)
        expect(result.result).to eq('fail'), result.result_message
      end
    end
  end
end
