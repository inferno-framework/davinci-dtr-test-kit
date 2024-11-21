require_relative 'shared_setup'

RSpec.describe DaVinciDTRTestKit::CQLTest do
  include_context('when running standard tests',
                  'payer_server_static_package', # group
                  suite_id = :dtr_payer_server,
                  "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package", # questionnaire_package_url
                  'Static', # retrieval_method
                  'http://example.org/fhir/R4') # url

  context 'when output is valid' do
    let(:scratch) do
      output_params = FHIR.from_contents(File.read(File.join(__dir__, '..', 'fixtures',
                                                             'questionnaire_package_output_params_conformant.json')))
      { static_questionnaire_bundles: [output_params.parameter.first.resource] }
    end

    describe 'static questionnaire package libraries test' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_libraries_test' } }

      it 'passes if questionnaire package has libraries' do
        result = run(runnable, test_session, scratch:, access_token:, retrieval_method:)
        expect(result.result).to eq('pass'), result.result_message
      end
    end

    describe 'static questionnaire extensions check' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_expressions_test' } }

      it 'passes if questionnaire package has valid extensions' do
        result = run(runnable, test_session, scratch:, access_token:, retrieval_method:)
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
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_libraries_test' } }

      it 'fails if questionnaire package has no libraries' do
        result = run(runnable, test_session, scratch:, access_token:, retrieval_method:)
        expect(result.result).to eq('fail'), result.result_message
      end
    end

    describe 'static questionnaire extensions check' do
      let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'static_form_expressions_test' } }

      it 'fails if questionnaire package has invalid extensions' do
        result = run(runnable, test_session, scratch:, access_token:, retrieval_method:)
        expect(result.result).to eq('fail'), result.result_message
      end
    end
  end
end
