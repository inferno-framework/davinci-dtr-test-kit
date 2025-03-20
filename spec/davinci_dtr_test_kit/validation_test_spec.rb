RSpec.describe DaVinciDTRTestKit::ValidationTest do
  let(:validation_url) { "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate" }
  let(:suite) { Inferno::Repositories::TestSuites.new.find('dtr_light_ehr') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }

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

  describe 'profile validation test' do
    let(:profile_validation_test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ValidationTest

        def self.suite
          Inferno::Repositories::TestSuites.new.find('dtr_payer_server')
        end

        validator do
          url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
        end

        input :coverage_resources

        def resource_type
          'Coverage'
        end

        run do
          perform_profile_validation_test(coverage_resources, resource_type,
                                          'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage|2.0.1')
        end
      end
    end

    let(:coverage_resources) do
      FHIR::Coverage.new(
        resourceType: 'Coverage',
        id: 'coverage-example',
        status: 'active',
        beneficiary: {
          reference: 'Patient/pat001'
        },
        payor: [
          {
            reference: 'http://example.org/fhir/Organization/example-payer',
            display: 'Payer XYZ'
          }
        ]
      ).to_json
    end
    let(:non_fhir_resources) do
      {
        resourceType: 'invalid',
        id: 'invalid-resource'
      }.to_json
    end
    let(:encounter_resources) do
      FHIR::Encounter.new(
        status: 'finished',
        period: {
          start: '2021-12-08T16:35:11.000Z',
          end: '2022-02-07T17:51:00.000Z'
        },
        subject: {
          reference: 'Patient/pat001'
        }
      ).to_json
    end
    let(:coverage_resources_bad) do
      {
        resourceType: 'Coverage',
        id: 'coverage-example-bad',
        payor: [
          {
            reference: 'http://example.org/fhir/Organization/example-payer',
            display: 'Payer XYZ'
          }
        ]
      }.to_json
    end

    before do
      Inferno::Repositories::Tests.new.insert(profile_validation_test)
    end

    it 'passes if coverage is conformant' do
      stub_request(:post, validation_url)
        .with(query: {
                profile: 'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage|2.0.1'
              })
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(profile_validation_test, coverage_resources:)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails if the resource does not contain a recognized FHIR object' do
      stub_request(:post, validation_url)
        .with(query: {
                profile: 'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage|2.0.1'
              })
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(profile_validation_test, coverage_resources: non_fhir_resources)
      expect(result.result).to eq('fail')
    end

    it 'fails if there is an unexpected resource type' do
      stub_request(:post, validation_url)
        .with(query: {
                profile: 'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-encounter|2.0.1'
              })
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(profile_validation_test, coverage_resources: encounter_resources)
      expect(result.result).to eq('fail')
    end

    it 'fails if the resource is not conformant to the profile' do
      stub_request(:post, validation_url)
        .with(query: {
                profile: 'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage|2.0.1'
              })
        .to_return(status: 200, body: FHIR::OperationOutcome.new(issue: { severity: 'error' }).to_json)

      result = run(profile_validation_test, coverage_resources: coverage_resources_bad)
      expect(result.result).to eq('fail')
    end
  end
end
