RSpec.describe DaVinciDTRTestKit::UpdateTest do
  let(:validator_url) { ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL') }
  let(:suite) { Inferno::Repositories::TestSuites.new.find('dtr_light_ehr') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:server_endpoint) { 'http://example.com' }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  describe 'behavior of update test' do
    let(:update_test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::UpdateTest

        fhir_resource_validator do
          url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL', 'http://hl7_validator_service:3500')

          cli_context do
            txServer nil
            displayWarnings true
            disableDefaultResourceFetcher true
          end

          igs('hl7.fhir.us.davinci-dtr', 'hl7.fhir.us.core')
        end

        fhir_client do
          url :server_endpoint
        end

        input :server_endpoint
        input :update_resources

        def resource_type
          'QuestionnaireResponse'
        end

        run do
          perform_update_test(update_resources, resource_type)
        end
      end
    end

    let(:operation_outcome_success) do
      {
        outcomes: [{
          issues: []
        }],
        sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
      }
    end

    let(:operation_outcome_failure) do
      {
        outcomes: [{
          issues: [{
            level: 'ERROR'
          }]
        }],
        sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
      }
    end

    let(:update_resources) do
      JSON.parse(
        File.read(File.join(
                    __dir__, '..', 'fixtures', 'questionnaire_response_create_update_example.json'
                  ))
      )
    end

    let(:encounter_resources) do
      [FHIR::Encounter.new(
        status: 'finished',
        period: {
          start: '2021-12-08T16:35:11.000Z',
          end: '2022-02-07T17:51:00.000Z'
        },
        subject: {
          reference: 'Patient/pat001'
        }
      )].to_json
    end

    let(:update_resource_id) { 'home-o2-questionnaireresponse' }

    before do
      Inferno::Repositories::Tests.new.insert(update_test)
    end

    it 'passes if a 200 is received' do
      validation_request = stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome_success.to_json)
      questionnaire_response_update_request =
        stub_request(:put, "#{server_endpoint}/QuestionnaireResponse/#{update_resource_id}")
          .to_return(status: 200, body: update_resources.to_json)

      result = run(update_test, update_resources: update_resources.to_json, server_endpoint:)
      expect(result.result).to eq('pass')
      expect(validation_request).to have_been_made
      expect(questionnaire_response_update_request).to have_been_made
    end

    it 'passes if a 201 is received' do
      validation_request = stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome_success.to_json)
      questionnaire_response_update_request =
        stub_request(:put, "#{server_endpoint}/QuestionnaireResponse/#{update_resource_id}")
          .to_return(status: 201, body: update_resources.to_json)

      result = run(update_test, update_resources: update_resources.to_json, server_endpoint:)
      expect(result.result).to eq('pass')
      expect(validation_request).to have_been_made
      expect(questionnaire_response_update_request).to have_been_made
    end

    it 'fails if the json is invalid' do
      result = run(update_test, update_resources: '[[', server_endpoint:)
      expect(result.result).to eq('fail')
    end

    it 'skips if the update_resources input is not an Array' do
      result = run(update_test, update_resources: update_resources[0].to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'Resources to update not inputted in list format, skipping test.'
      )
    end

    it 'skips if update_resources input is empty' do
      result = run(update_test, update_resources: [], server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        "Input 'update_resources' is nil, skipping test."
      )
    end

    it 'skips if empty resource json is inputted' do
      result = run(update_test, update_resources: [{}].to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Update requests, skipping test.'
      )
    end

    it 'skips if inputted resource is the wrong resource type' do
      result = run(update_test, update_resources: encounter_resources, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Update requests, skipping test.'
      )
    end

    it 'skips if passed in QuestionnaireResponse resource is invalid' do
      validation_request = stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome_failure.to_json)

      result = run(update_test, update_resources: update_resources.to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Update requests, skipping test.'
      )
      expect(validation_request).to have_been_made
    end

    it 'fails if QuestionnaireResponse creation interaction returns non 201/200' do
      validation_request = stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome_success.to_json)
      questionnaire_response_update_request =
        stub_request(:put, "#{server_endpoint}/QuestionnaireResponse/#{update_resource_id}").to_return(status: 400)

      result = run(update_test, update_resources: update_resources.to_json, server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 200, 201, but received 400')
      expect(validation_request).to have_been_made
      expect(questionnaire_response_update_request).to have_been_made
    end
  end
end
