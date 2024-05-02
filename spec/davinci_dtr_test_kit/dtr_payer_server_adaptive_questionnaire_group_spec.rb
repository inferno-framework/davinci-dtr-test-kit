require'davinci_dtr_test_kit/validation_test'
RSpec.describe DaVinciDTRTestKit::ValidationTest do
  include Rack::Test::Methods

  def app
    Inferno::Web.app
  end

  # let(:payer_server_adaptive_questionnaire_request_validation) do
  #   Inferno::Repositories::Tests.new.find('payer_server_adaptive_questionnaire_request_validation')
  # end

  let(:suite) { Inferno::Repositories::TestSuites.new.find('dtr_payer_server') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  # let(:server_endpoint) { 'http://example.com/fhir' }

  let(:url) do
    'http://example.com/fhir'
  end

  let(:access_token) do
    '1234567'
  end

  let(:initial_questionnaire_request) do
    File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
  end

  let(:adaptive_request_test) do
    Class.new(DaVinciDTRTestKit::AdaptiveQuestionnairePackageValidationTest) do
      fhir_client { url :url }
      input :url, :access_token, :initial_questionnaire_request
    end
  end

  # def run(runnable, inputs = {})
  #   test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
  #   test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
  #   inputs.each do |name, value|
  #     # puts "name: #{name}"
  #     # puts "value: #{value}"
  #     # puts "name type: #{runnable.config.input_type(name)}"
  #     session_data_repo.save(
  #       test_session_id: test_session.id,
  #       name:,
  #       value:,
  #       # type: runnable.config.input_type(name)
  #       type: 'textarea'
  #     )
  #   end
  #   require 'debug/open_nonstop'
  #   debugger
  #   Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  # end

  it 'passes if given input request is conformant' do
    # stub_request(:post, "#{url}/Questionnaire/$questionnaire-package/")
    #   .with(
    #     body: JSON.parse(initial_questionnaire_request)
    #   )
    #   .to_return(status: 200, body: {}.to_json)

    result = run(adaptive_request_test, test_session, url:, access_token:, initial_questionnaire_request:)
    # result = run(adaptive_request_test, initial_questionnaire_request:, url:, access_token:)
    require 'debug/open_nonstop'
    debugger
    expect(result.result).to eq('pass')
  end

  # it 'passes if the PA response has a 200 status for Claim/$submit operation' do
  #   stub_request(:post, "#{server_endpoint}/Claim/$submit")
  #     .with(
  #       body: JSON.parse(questionnaire_package_request_body)
  #     )
  #     .to_return(status: 200, body: {}.to_json)

  #   result = run(test, questionnaire_package_request_body:, server_endpoint:)
  #   expect(result.result).to eq('pass')
  # end



end
  # let(:questionnaire_request_resources) do
  #   # dump = File.read('spec/fixtures/questionnaire_request_resources.dump')
  #   # YAML.load(File.read('spec/fixtures/questionnaire_request_resources.dump'))
  #   YAML.unsafe_load_file('spec/fixtures/questionnaire_request_resources.dump')
  #   # Marshal.restore(dump)
  # end
  # let(:next_request_resources) do
  #   # File.open(file_name, 'w') { |file| file.write(YAML.dump(array_of_objects)) }
  #   # dump = File.read('spec/fixtures/next_request_resources.dump')
  #   # YAML.load(File.read('spec/fixtures/next_request_resources.dump'))
  #   # , permitted_classes: [Inferno::Entities::Request]
  #   YAML.unsafe_load_file('spec/fixtures/next_request_resources.dump')
  #   # Marshal.restore(dump)
  # end
  # require 'debug/open_nonstop'
  # debugger


  # describe 'DTR request resource validation' do
  #   it 'passes if questionnaire-package requests validate' do
  #     perform_request_validation_test(
  #       questionnaire_request_resources,
  #       :parameters,
  #       'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters',
  #       'example.com')
  #   end

  #   it 'passes if next-question requests validate' do
  #     perform_request_validation_test(
  #       next_request_resources,
  #       :questionnaireResponse,
  #       'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse',
  #       'example.com')
  #   end
  # end

  # describe 'Payer server response resource validation' do
  #   it 'passes if questionnaire-package responses validate' do
  #     perform_response_validation_test(
  #       questionnaire_request_resources,
  #       :parameters,
  #       'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')
  #   end

  #   it 'passes if next-question responses validate' do
  #     perform_response_validation_test(
  #       next_request_resources,
  #       :questionnaireResponse,
  #       'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse')
  #   end
  # end
# end
