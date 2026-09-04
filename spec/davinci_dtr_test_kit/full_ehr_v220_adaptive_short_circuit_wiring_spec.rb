require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/adaptive_questionnaires_completed_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_request_validation_test'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/response/dtr_next_question_response_validation_test'

# When config.options[:adaptive_questionnaires_optional] is set and a scenario's
# $questionnaire-package responses turned out to contain no adaptive Questionnaires (e.g.
# only standard ones), DTRFullEHRV220AdaptiveQuestionnairesCompletedTest passes vacuously
# and sets scratch[:short_circuit_adaptive] so the $next-question request/response validation
# tests -- which would otherwise have nothing to validate -- also pass vacuously instead of
# reporting a misleading "no request was made" skip. These specs verify that wiring end to end,
# the way it would actually run within DTRFullEHRV220AbstractAdaptive.
RSpec.describe 'DTR Full EHR v2.2.0 adaptive short-circuit wiring' do # rubocop:disable RSpec/DescribeClass
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  let(:completed_test_class) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220AdaptiveQuestionnairesCompletedTest) do
      id :adaptive_short_circuit_wiring_completed_spec_test
      config options: { adaptive_questionnaires_optional: true }
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(completed_test_class) unless tests_repo.exists?(completed_test_class.id.to_s)
  end

  def create_qp_request(response_body)
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package',
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG],
      status: 200
    )
  end

  def standard_qp_response_json
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: {
            resourceType: 'Questionnaire', status: 'active', url: 'http://example.org/Questionnaire/std',
            item: [{ linkId: 'Standard', type: 'string' }]
          } }] } }
      ]
    }.to_json
  end

  # Sets up the scenario the completed test is meant to short-circuit: a Questionnaire Package
  # request was made and returned only a standard (non-adaptive) Questionnaire, so no
  # $next-question requests are expected to ever be seen.
  def scratch_after_vacuous_completion
    create_qp_request(standard_qp_response_json)
    scratch = {}
    completed_result = run(completed_test_class, {}, scratch)
    expect(completed_result.result).to eq('pass'), completed_result.result_message
    scratch
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionRequestValidationTest do
    it 'passes with the adaptive short-circuit message instead of skipping for lack of a request' do
      scratch = scratch_after_vacuous_completion

      result = run(described_class, {}, scratch)

      expect(result.result).to eq('pass')
      expect(result.result_message)
        .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::SHORT_CIRCUIT_ADAPTIVE_MESSAGE)
    end

    it 'runs its normal validation, unaffected, when the flag was never set' do
      result = run(described_class, {}, {})

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('A $next-question request must be made')
    end
  end

  describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionResponseValidationTest do
    it 'passes with the adaptive short-circuit message instead of skipping for lack of a request' do
      scratch = scratch_after_vacuous_completion

      result = run(described_class, {}, scratch)

      expect(result.result).to eq('pass')
      expect(result.result_message)
        .to eq(DaVinciDTRTestKit::ShortCircuitInteractionVerification::SHORT_CIRCUIT_ADAPTIVE_MESSAGE)
    end

    it 'runs its normal validation, unaffected, when the flag was never set' do
      result = run(described_class, {}, {})

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('A Next Question request must be made')
    end
  end
end
