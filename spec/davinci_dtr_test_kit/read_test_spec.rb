RSpec.describe DaVinciDTRTestKit::ReadTest do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('dtr_light_ehr') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:url) { 'http://example.com' }
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }

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

  describe 'Behavior of read test' do
    let(:read_test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::ReadTest

        fhir_client { url :url }
        input :url, :resource_ids

        def resource_type
          'Coverage'
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
    let(:coverage_resources) do
      FHIR::Coverage.new(
        resourceType: 'Coverage',
        id: 'coverage-example',
        text: {
          status: 'generated',
          div: "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Coverage</b><a name=\"example\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Coverage &quot;example&quot; </p></div><p><b>identifier</b>: Member Number:\u00a012345</p><p><b>status</b>: active</p><p><b>type</b>: extended healthcare <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-v3-ActCode.html\">ActCode</a>#EHCPOL)</span></p><p><b>policyHolder</b>: <a href=\"http://example.org/FHIR/Organization/CBI35\">http://example.org/FHIR/Organization/CBI35</a></p><p><b>subscriber</b>: <a href=\"Patient-example.html\">Patient/example</a> &quot; SHAW&quot;</p><p><b>beneficiary</b>: <a href=\"Patient-example.html\">Patient/example</a> &quot; SHAW&quot;</p><p><b>dependent</b>: 0</p><p><b>relationship</b>: Self <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-subscriber-relationship.html\">SubscriberPolicyholder Relationship Codes</a>#self)</span></p><p><b>period</b>: 2011-05-23 --&gt; 2012-05-23</p><p><b>payor</b>: <a href=\"http://example.org/fhir/Organization/example-payer\">http://example.org/fhir/Organization/example-payer: Payer XYZ</a></p><h3>Classes</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td><td><b>Value</b></td><td><b>Name</b></td></tr><tr><td style=\"display: none\">*</td><td>Group <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-coverage-class.html\">Coverage Class Codes</a>#group)</span></td><td>CB135</td><td>Corporate Baker's Inc. Local #35</td></tr></table></div>"
        },
        identifier: [
          {
            type: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/v2-0203',
                  code: 'MB'
                }
              ]
            },
            system: 'http://example.com/fhir/NampingSystem/certificate',
            value: '12345'
          }
        ],
        status: 'active',
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
              code: 'EHCPOL',
              display: 'extended healthcare'
            }
          ]
        },
        policyHolder: {
          reference: 'http://example.org/FHIR/Organization/CBI35'
        },
        subscriber: {
          reference: 'Patient/pat001'
        },
        beneficiary: {
          reference: 'Patient/pat001'
        },
        dependent: '0',
        relationship: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/subscriber-relationship',
              code: 'self'
            }
          ]
        },
        period: {
          start: '2011-05-23',
          end: '2012-05-23'
        },
        payor: [
          {
            reference: 'http://example.org/fhir/Organization/example-payer',
            display: 'Payer XYZ'
          }
        ],
        class: [
          {
            type: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/coverage-class',
                  code: 'group'
                }
              ]
            },
            value: 'CB135',
            name: "Corporate Baker's Inc. Local #35"
          }
        ]
      )
    end

    before do
      Inferno::Repositories::Tests.new.insert(read_test)
    end

    it 'passes if a 200 is received' do
      stub_request(:get, "#{url}/Coverage/coverage-example")
        .to_return(status: 200, body: coverage_resources.to_json)

      result = run(read_test, resource_ids:, url:)
      expect(result.result).to eq('pass')
    end
  end
end
