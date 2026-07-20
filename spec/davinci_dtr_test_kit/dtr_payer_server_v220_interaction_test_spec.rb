require 'davinci_dtr_test_kit/server/v2.2.0/interaction_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::InteractionTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:canonical) { 'urn:example:adaptive-q' }
  let(:url) { 'https://payer.example.com/fhir' }
  let(:qp_url) { "#{url}/Questionnaire/$questionnaire-package" }
  let(:nq_url) { "#{url}/Questionnaire/$next-question" }
  let(:vs_expand_url) { "#{url}/ValueSet/$expand" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  # A test subclass that adds its own fhir_client so it can be run standalone
  # without requiring the parent group's fhir_client configuration.
  let(:test_class) do
    Class.new(described_class) do
      id :dtr_v220_payer_interaction_spec
      input :backend_services_smart_auth_info, optional: true

      fhir_client { url :url }
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [test_class])
      .first&.messages || []
  end

  # ---------------------------------------------------------------------------
  # Helpers — FHIR fixture builders
  # ---------------------------------------------------------------------------

  def static_qp_response
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [FHIR::Bundle::Entry.new(resource: FHIR::Questionnaire.new(url: canonical, status: 'draft'))]
          )
        )
      ]
    ).to_json
  end

  def adaptive_qp_response
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::Questionnaire.new(
                  url: canonical, status: 'draft',
                  extension: [FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                    valueBoolean: true
                  )]
                )
              )
            ]
          )
        )
      ]
    ).to_json
  end

  def qp_response_with_value_set
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::ValueSet.new(url: 'http://example.com/vs', status: 'draft')
              )
            ]
          )
        )
      ]
    ).to_json
  end

  def completed_nq_response
    FHIR::QuestionnaireResponse.new(
      status: 'completed',
      contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
    ).to_json
  end

  def inprogress_nq_response(items: [])
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      contained: [
        FHIR::Questionnaire.new(
          url: canonical, status: 'draft',
          item: items.map { |id| FHIR::Questionnaire::Item.new(linkId: id, type: 'string') }
        )
      ]
    ).to_json
  end

  def qr_template(answer_items: [])
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      item: answer_items.map do |id|
        FHIR::QuestionnaireResponse::Item.new(
          linkId: id,
          answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: "answer-for-#{id}")]
        )
      end,
      contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
    ).to_json
  end

  def single_parameters_input
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'coverage', valueString: 'cov-1')]
    ).to_json
  end

  # ---------------------------------------------------------------------------
  # extract_fhir_parameters (tested via run result)
  # ---------------------------------------------------------------------------

  describe 'input parsing: $questionnaire-package parameters' do
    it 'parses a single Parameters JSON and makes one QP request' do
      stub_request(:post, qp_url).to_return(status: 200, body: static_qp_response)
      result = run(test_class, url:, questionnaire_package_request_parameters: single_parameters_input)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, qp_url).once
    end

    it 'parses an array of Parameters JSON and makes one QP request per entry' do
      two_params = [JSON.parse(single_parameters_input), JSON.parse(single_parameters_input)].to_json
      stub_request(:post, qp_url).to_return(status: 200, body: static_qp_response)
      result = run(test_class, url:, questionnaire_package_request_parameters: two_params)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, qp_url).twice
    end

    it 'warns and skips non-Parameters entries' do
      mixed = [JSON.parse(single_parameters_input),
               { 'resourceType' => 'Patient' }].to_json
      stub_request(:post, qp_url).to_return(status: 200, body: static_qp_response)
      result = run(test_class, url:, questionnaire_package_request_parameters: mixed)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, qp_url).once
      expect(result_messages.map(&:message).join).to match(/skipping.*Parameters/)
    end

    it 'fails when questionnaire_package_request_parameters is not valid JSON' do
      result = run(test_class, url:, questionnaire_package_request_parameters: 'not json')
      expect(result.result).to eq('fail'), result.result_message
    end
  end

  # ---------------------------------------------------------------------------
  # extract_fhir_questionnaire_response_templates (tested via run result)
  # ---------------------------------------------------------------------------

  describe 'input parsing: QuestionnaireResponse templates' do
    it 'treats nil templates as no adaptive follow-up (no NQ requests)' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      result = run(test_class, url:, questionnaire_package_request_parameters: single_parameters_input)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to_not have_requested(:post, nq_url)
    end

    it 'parses a single QR template JSON' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      stub_request(:post, nq_url).to_return(status: 200, body: completed_nq_response)
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, nq_url).once
    end

    it 'warns and skips non-QR template entries' do
      mixed_templates = [JSON.parse(qr_template),
                         { 'resourceType' => 'Patient' }].to_json
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      stub_request(:post, nq_url).to_return(status: 200, body: completed_nq_response)
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: mixed_templates)
      expect(result.result).to eq('pass'), result.result_message
      expect(result_messages.map(&:message).join).to match(/skipping.*QuestionnaireResponse/)
    end

    it 'fails when questionnaire_response_templates is not valid JSON' do
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: 'not json')
      expect(result.result).to eq('fail'), result.result_message
    end
  end

  # ---------------------------------------------------------------------------
  # QP → ValueSet expand
  # ---------------------------------------------------------------------------

  describe 'ValueSet expansion' do
    it 'expands unexpanded ValueSets found in the package bundle' do
      stub_request(:post, qp_url).to_return(status: 200, body: qp_response_with_value_set)
      stub_request(:post, vs_expand_url).to_return(
        status: 200,
        body: FHIR::ValueSet.new(url: 'http://example.com/vs', status: 'draft').to_json
      )
      result = run(test_class, url:, questionnaire_package_request_parameters: single_parameters_input)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, vs_expand_url).once
    end

    it 'does not expand a ValueSet that already has an expansion' do
      already_expanded = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'packagebundle',
            resource: FHIR::Bundle.new(
              type: 'collection',
              entry: [FHIR::Bundle::Entry.new(
                resource: FHIR::ValueSet.new(
                  url: 'http://example.com/vs', status: 'draft',
                  expansion: FHIR::ValueSet::Expansion.new(timestamp: '2024-01-01', contains: [])
                )
              )]
            )
          )
        ]
      ).to_json
      stub_request(:post, qp_url).to_return(status: 200, body: already_expanded)
      result = run(test_class, url:, questionnaire_package_request_parameters: single_parameters_input)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to_not have_requested(:post, vs_expand_url)
    end
  end

  # ---------------------------------------------------------------------------
  # $next-question loop
  # ---------------------------------------------------------------------------

  describe '$next-question interaction' do
    it 'makes a single NQ request when the server immediately returns a completed form' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      stub_request(:post, nq_url).to_return(status: 200, body: completed_nq_response)
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, nq_url).once
      expect(result_messages.map(&:message).join).to_not match(/did not result in a completed form/)
    end

    it 'makes multiple NQ requests iterating through new questions until the form completes' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      stub_request(:post, nq_url).to_return(
        { status: 200, body: inprogress_nq_response(items: ['Q1']) },
        { status: 200, body: completed_nq_response }
      )
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template(answer_items: ['Q1']))
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to have_requested(:post, nq_url).twice
      expect(result_messages.map(&:message).join).to_not match(/did not result in a completed form/)
    end

    it 'records a warning message when NQ requests do not produce a completed form' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      # Server adds Q1, then returns the same Q1 again (no new items → loop ends without completion)
      stub_request(:post, nq_url).to_return(
        { status: 200, body: inprogress_nq_response(items: ['Q1']) },
        { status: 200, body: inprogress_nq_response(items: ['Q1']) }
      )
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template(answer_items: ['Q1']))
      expect(result.result).to eq('pass'), result.result_message
      expect(result_messages.map(&:message).join).to match(/did not result in a completed form/)
    end

    it 'skips the NQ loop for adaptive questionnaires when no template is provided' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to_not have_requested(:post, nq_url)
      expect(result_messages.map(&:message).join).to match(/No QuestionnaireResponse template/)
    end

    it 'does not attempt NQ requests for static (non-adaptive) questionnaires' do
      stub_request(:post, qp_url).to_return(status: 200, body: static_qp_response)
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template)
      expect(result.result).to eq('pass'), result.result_message
      expect(WebMock).to_not have_requested(:post, nq_url)
    end

    it 'records a warning and continues when the NQ server returns a non-2xx response' do
      stub_request(:post, qp_url).to_return(status: 200, body: adaptive_qp_response)
      stub_request(:post, nq_url).to_return(status: 500, body: 'error')
      result = run(test_class, url:,
                               questionnaire_package_request_parameters: single_parameters_input,
                               questionnaire_response_templates: qr_template)
      expect(result.result).to eq('pass'), result.result_message
      expect(result_messages.map(&:message).join).to match(/did not result in a completed form/)
    end
  end
end
