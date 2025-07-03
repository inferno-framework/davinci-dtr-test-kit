RSpec.describe DaVinciDTRTestKit::CreateTest, :runnable do
  let(:suite_id) { 'dtr_light_ehr' }
  let(:server_endpoint) { 'http://example.com' }

  describe 'Behavior of create test' do
    let(:create_test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::CreateTest

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
        input :create_resources

        def resource_type
          'QuestionnaireResponse'
        end

        run do
          perform_create_test(create_resources, resource_type)
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

    let(:create_resources) do
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

    before do
      Inferno::Repositories::Tests.new.insert(create_test)
    end

    it 'passes if a 201 is received' do
      validation_request = stub_request(:post, validation_url)
        .to_return(status: 200, body: operation_outcome_success.to_json)
      questionnaire_response_create_request = stub_request(:post, "#{server_endpoint}/QuestionnaireResponse")
        .to_return(status: 201, body: create_resources.to_json)

      result = run(create_test, create_resources: create_resources.to_json, server_endpoint:)
      expect(result.result).to eq('pass')
      expect(validation_request).to have_been_made
      expect(questionnaire_response_create_request).to have_been_made
    end

    it 'fails if the json is invalid' do
      result = run(create_test, create_resources: '[[', server_endpoint:)
      expect(result.result).to eq('fail')
    end

    it 'skips if the create_resources input is not an Array' do
      result = run(create_test, create_resources: create_resources[0].to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'Resources to create not inputted in list format, skipping test.'
      )
    end

    it 'skips if create_resources input is empty' do
      result = run(create_test, create_resources: [], server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        "Input 'create_resources' is nil, skipping test."
      )
    end

    it 'skips if empty resource json is inputted' do
      result = run(create_test, create_resources: [{}].to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Create requests, skipping test.'
      )
    end

    it 'skips if inputted resource is the wrong resource type' do
      result = run(create_test, create_resources: encounter_resources, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Create requests, skipping test.'
      )
    end

    it 'skips if passed in QuestionnaireResponse resource is invalid' do
      validation_request = stub_request(:post, validation_url)
        .to_return(status: 200, body: operation_outcome_failure.to_json)

      result = run(create_test, create_resources: create_resources.to_json, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No valid QuestionnaireResponse resources were provided to send in Create requests, skipping test.'
      )
      expect(validation_request).to have_been_made
    end

    it 'fails if QuestionnaireResponse creation interaction returns non 201' do
      validation_request = stub_request(:post, validation_url)
        .to_return(status: 200, body: operation_outcome_success.to_json)
      questionnaire_response_create_request = stub_request(:post, "#{server_endpoint}/QuestionnaireResponse")
        .to_return(status: 400)

      result = run(create_test, create_resources: create_resources.to_json, server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 201, but received 400')
      expect(validation_request).to have_been_made
      expect(questionnaire_response_create_request).to have_been_made
    end
  end
end
