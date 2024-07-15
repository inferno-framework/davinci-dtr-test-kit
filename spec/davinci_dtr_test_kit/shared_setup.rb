RSpec.shared_context('when running standard tests') do |group,
                                                        suite_id,
                                                        questionnaire_package_url,
                                                        retrieval_method, url|
  def app
    Inferno::Web.app
  end
  let(:group) { Inferno::Repositories::TestGroups.new.find(group) }
  let(:suite_id) { suite_id }
  let(:questionnaire_package_url) { questionnaire_package_url }
  let(:url) { url }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:retrieval_method) { retrieval_method }
  let(:access_token) { '1234' }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:validation_url) { "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate" }

  def run(runnable, test_session, inputs = {})

    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: 'textarea'
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end
end
