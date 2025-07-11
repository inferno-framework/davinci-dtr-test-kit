RSpec.describe DaVinciDTRTestKit::ReadTest, :runnable do
  let(:suite_id) { 'dtr_light_ehr' }
  let(:url) { 'http://example.com' }

  describe 'Behavior of read test' do
    let(:read_test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ReadTest

        fhir_client { url :url }
        input :url, :resource_ids

        def resource_type
          'Coverage'
        end

        def scratch_resources
          scratch[:coverage_resources] ||= {}
        end

        def coverage_id_list
          resource_ids.split(',').map(&:strip)
        end

        run do
          perform_read_test(coverage_id_list, resource_type)
        end
      end
    end
    let(:resource_ids) { 'coverage-example' }
    let(:coverage_resource) do
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
      )
    end
    let(:coverage_resource_bad_id) do
      FHIR::Coverage.new(
        resourceType: 'Coverage',
        id: 'coverage-example-bad',
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
      )
    end
    let(:encounter_resource) do
      FHIR::Encounter.new(
        status: 'finished',
        period: {
          start: '2021-12-08T16:35:11.000Z',
          end: '2022-02-07T17:51:00.000Z'
        },
        subject: {
          reference: 'Patient/pat001'
        }
      )
    end

    before do
      Inferno::Repositories::Tests.new.insert(read_test)
    end

    it 'passes if a 200 is received' do
      stub_request(:get, "#{url}/Coverage/coverage-example")
        .to_return(status: 200, body: coverage_resource.to_json)

      result = run(read_test, resource_ids:, url:)
      expect(result.result).to eq('pass')
    end

    it 'fails if a 400 is received' do
      stub_request(:get, "#{url}/Coverage/coverage-example")
        .to_return(status: 400)

      result = run(read_test, resource_ids:, url:)
      expect(result.result).to eq('fail')
    end

    it 'fails if there is an unexpected resource type' do
      stub_request(:get, "#{url}/Coverage/coverage-example")
        .to_return(status: 200, body: encounter_resource.to_json)

      result = run(read_test, resource_ids:, url:)
      expect(result.result).to eq('fail')
    end

    it 'fails if there is an unexpected id' do
      stub_request(:get, "#{url}/Coverage/coverage-example")
        .to_return(status: 200, body: coverage_resource_bad_id.to_json)

      result = run(read_test, resource_ids:, url:)
      expect(result.result).to eq('fail')
    end
  end
end
