RSpec.describe DaVinciDTRTestKit::ValidationTest do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('payer_server_adaptive_questionnaire') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:questionnaire_request_resources) do
    dump = File.read('spec/fixtures/questionnaire_request_resources.dump')
    Marshal.restore(dump)
  end
  let(:next_request_resources) do
    dump = File.read('spec/fixtures/next_request_resources.dump')
    Marshal.restore(dump)
  end

  describe 'DTR request resource validation' do
    it 'passes if questionnaire-package requests validate' do
      perform_request_validation_test(
        questionnaire_request_resources,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters',
        questionnaire_package_url)
    end

    it 'passes if next-question requests validate' do
      perform_request_validation_test(
        next_request_resources,
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse',
        next_url)
    end
  end

  describe 'Payer server response resource validation' do
    it 'passes if questionnaire-package responses validate' do
      perform_response_validation_test(
        questionnaire_request_resources,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')
    end

    it 'passes if next-question responses validate' do
      perform_response_validation_test(
        next_request_resources,
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse')
    end
  end
end