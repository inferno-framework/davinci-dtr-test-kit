require 'davinci_dtr_test_kit/server/v2.2.0/client_simulation'

MockFhirResponse = Struct.new(:status, :response_body)

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ClientSimulation do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:sim) { simulation_class.new }

  let(:simulation_class) do
    Class.new do
      include DaVinciDTRTestKit::DTRPayerServerV220::ClientSimulation

      attr_reader :messages, :recorded_requests

      def initialize
        @messages = []
        @recorded_requests = []
        @queued_responses = []
      end

      def add_message(level, message)
        @messages << { level:, message: }
      end

      def queue_response(response)
        @queued_responses << response
      end

      def fhir_operation(url, body:, headers:, tags: [])
        @recorded_requests << { url:, body:, tags:, headers: }
        @queued_responses.shift || MockFhirResponse.new(200, {}.to_json)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def make_questionnaire(url:, version: nil, adaptive: false, items: [])
    extensions = if adaptive
                   [
                     FHIR::Extension.new(
                       url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                       valueBoolean: true
                     )
                   ]
                 else
                   []
                 end
    FHIR::Questionnaire.new(url:, version:, status: 'draft', extension: extensions, item: items)
  end

  def qr_with_contained(questionnaire, items: [], status: 'in-progress')
    FHIR::QuestionnaireResponse.new(status:, item: items, contained: [questionnaire])
  end

  def qr_item(link_id, answer_value: nil, children: [])
    item = FHIR::QuestionnaireResponse::Item.new(linkId: link_id, item: children)
    item.answer = [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: answer_value)] if answer_value
    item
  end

  def q_item(link_id, children: [])
    FHIR::Questionnaire::Item.new(linkId: link_id, type: 'string', item: children)
  end

  # ---------------------------------------------------------------------------
  # item_list
  # ---------------------------------------------------------------------------

  describe '#item_list' do
    it 'returns empty for a questionnaire with no items' do
      q = FHIR::Questionnaire.new(status: 'draft')
      expect(sim.send(:item_list, q)).to eq([])
    end

    it 'returns [linkId] for a single flat item' do
      q = FHIR::Questionnaire.new(item: [q_item('Q1')])
      expect(sim.send(:item_list, q)).to eq(['Q1'])
    end

    it 'returns parent before children for nested items' do
      q = FHIR::Questionnaire.new(item: [
                                    q_item('G1', children: [q_item('Q1'), q_item('Q2')])
                                  ])
      result = sim.send(:item_list, q)
      expect(result.index('G1')).to be < result.index('Q1')
      expect(result.index('G1')).to be < result.index('Q2')
    end

    it 'returns items in document order for deeply nested structure' do
      q = FHIR::Questionnaire.new(item: [
                                    q_item('G1', children: [q_item('G1.1', children: [q_item('Q1')])])
                                  ])
      expect(sim.send(:item_list, q)).to eq(['G1', 'G1.1', 'Q1'])
    end

    it 'deduplicates repeated linkIds' do
      q = FHIR::Questionnaire.new(item: [q_item('Q1'), q_item('Q1')])
      expect(sim.send(:item_list, q).count('Q1')).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # identify_new_items
  # ---------------------------------------------------------------------------

  describe '#identify_new_items' do
    it 'returns empty when questionnaire has not changed' do
      q = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1')])
      form = qr_with_contained(q)
      expect(sim.send(:identify_new_items, form, form)).to eq([])
    end

    it 'returns linkIds added in the returned form' do
      q_orig = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1')])
      q_updated = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1'), q_item('Q2')])
      original = qr_with_contained(q_orig)
      updated = qr_with_contained(q_updated)
      expect(sim.send(:identify_new_items, original, updated)).to eq(['Q2'])
    end

    it 'does not report removed items as new' do
      q_orig = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1'), q_item('Q2')])
      q_updated = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1')])
      expect(sim.send(:identify_new_items, qr_with_contained(q_orig), qr_with_contained(q_updated))).to eq([])
    end

    it 'returns new nested items in parent-first order' do
      q_orig = make_questionnaire(url: 'http://example.com/q', items: [q_item('Q1')])
      q_updated = make_questionnaire(url: 'http://example.com/q', items: [
                                       q_item('Q1'),
                                       q_item('G1', children: [q_item('G1.Q1')])
                                     ])
      result = sim.send(:identify_new_items, qr_with_contained(q_orig), qr_with_contained(q_updated))
      expect(result.index('G1')).to be < result.index('G1.Q1')
    end

    it 'returns empty instead of crashing when submitted form has no contained Questionnaire' do
      bare_qr = FHIR::QuestionnaireResponse.new(status: 'in-progress')
      updated = qr_with_contained(make_questionnaire(url: 'http://example.com/q'))
      expect { sim.send(:identify_new_items, bare_qr, updated) }.to_not raise_error
      expect(sim.send(:identify_new_items, bare_qr, updated)).to eq([])
    end

    it 'returns empty instead of crashing when returned form has no contained Questionnaire' do
      original = qr_with_contained(make_questionnaire(url: 'http://example.com/q'))
      bare_qr = FHIR::QuestionnaireResponse.new(status: 'in-progress')
      expect { sim.send(:identify_new_items, original, bare_qr) }.to_not raise_error
      expect(sim.send(:identify_new_items, original, bare_qr)).to eq([])
    end
  end

  # ---------------------------------------------------------------------------
  # search_for_item
  # ---------------------------------------------------------------------------

  describe '#search_for_item' do
    let(:template_items) do
      [
        qr_item('G1', children: [qr_item('Q1'), qr_item('Q2')]),
        qr_item('Q3')
      ]
    end

    it 'finds a top-level item and returns it with an empty address' do
      answer, address = sim.send(:search_for_item, 'Q3', template_items, [])
      expect(answer.linkId).to eq('Q3')
      expect(address).to eq([])
    end

    it 'finds a nested item and returns it with its parent address' do
      answer, address = sim.send(:search_for_item, 'Q1', template_items, [])
      expect(answer.linkId).to eq('Q1')
      expect(address).to eq(['G1'])
    end

    it 'returns nil for an item not in the list' do
      expect(sim.send(:search_for_item, 'MISSING', template_items, [])).to be_nil
    end

    it 'strips children from the duplicated answer' do
      answer, = sim.send(:search_for_item, 'G1', template_items, [])
      expect(answer.item).to be_empty
    end

    it 'does not mutate the original template item when stripping children' do
      original_children = template_items.first.item.length
      sim.send(:search_for_item, 'G1', template_items, [])
      expect(template_items.first.item.length).to eq(original_children)
    end
  end

  # ---------------------------------------------------------------------------
  # add_new_answers
  # ---------------------------------------------------------------------------

  describe '#add_new_answers' do
    let(:template) do
      FHIR::QuestionnaireResponse.new(item: [
                                        qr_item('G1', children: [qr_item('Q1', answer_value: 'nested-answer')]),
                                        qr_item('Q2', answer_value: 'top-answer')
                                      ])
    end

    it 'adds a top-level item to the QR' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [])
      sim.send(:add_new_answers, qr, ['Q2'], template)
      expect(qr.item.map(&:linkId)).to include('Q2')
    end

    it 'adds a nested item under its pre-existing parent' do
      qr = FHIR::QuestionnaireResponse.new(
        status: 'in-progress',
        item: [FHIR::QuestionnaireResponse::Item.new(linkId: 'G1', item: [])]
      )
      sim.send(:add_new_answers, qr, ['Q1'], template)
      g1 = qr.item.find { |i| i.linkId == 'G1' }
      expect(g1.item.map(&:linkId)).to include('Q1')
    end

    it 'adds parent before children when both are new (parent-first ordering)' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [])
      sim.send(:add_new_answers, qr, ['G1', 'Q1'], template)
      expect(qr.item.map(&:linkId)).to include('G1')
      g1 = qr.item.find { |i| i.linkId == 'G1' }
      expect(g1.item.map(&:linkId)).to include('Q1')
    end

    it 'skips items not found in the template instead of adding nil' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [])
      sim.send(:add_new_answers, qr, ['MISSING'], template)
      expect(qr.item).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # new_answers?
  # ---------------------------------------------------------------------------

  describe '#new_answers?' do
    let(:template) do
      FHIR::QuestionnaireResponse.new(item: [
                                        qr_item('G1', children: [qr_item('Q1')]),
                                        qr_item('Q2')
                                      ])
    end

    it 'returns true when template has a matching top-level item' do
      expect(sim.send(:new_answers?, ['Q2'], template)).to be true
    end

    it 'returns true when match is a nested item in the template' do
      expect(sim.send(:new_answers?, ['Q1'], template)).to be true
    end

    it 'returns false when no new item appears in the template' do
      expect(sim.send(:new_answers?, ['MISSING'], template)).to be false
    end

    it 'returns true when at least one new item matches even if others do not' do
      expect(sim.send(:new_answers?, ['MISSING', 'Q2'], template)).to be true
    end

    it 'returns false instead of crashing when template item has nil children' do
      item_with_nil_children = FHIR::QuestionnaireResponse::Item.new(linkId: 'G1')
      bare_template = FHIR::QuestionnaireResponse.new(item: [item_with_nil_children])
      expect { sim.send(:new_answers?, ['Q1'], bare_template) }.to_not raise_error
      expect(sim.send(:new_answers?, ['Q1'], bare_template)).to be false
    end
  end

  # ---------------------------------------------------------------------------
  # add_answer_under_address
  # ---------------------------------------------------------------------------

  describe '#add_answer_under_address' do
    it 'adds at root when address is empty' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [])
      answer = qr_item('Q1')
      sim.send(:add_answer_under_address, qr, answer, [])
      expect(qr.item.map(&:linkId)).to include('Q1')
    end

    it 'navigates to the correct parent and adds the item' do
      g1 = FHIR::QuestionnaireResponse::Item.new(linkId: 'G1', item: [])
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [g1])
      answer = qr_item('Q1')
      sim.send(:add_answer_under_address, qr, answer, ['G1'])
      expect(g1.item.map(&:linkId)).to include('Q1')
    end

    it 'does not crash when an intermediate address node is missing' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', item: [])
      answer = qr_item('Q1')
      expect { sim.send(:add_answer_under_address, qr, answer, ['MISSING_PARENT']) }.to_not raise_error
    end
  end

  # ---------------------------------------------------------------------------
  # canonical_url_for_resource
  # ---------------------------------------------------------------------------

  describe '#canonical_url_for_resource' do
    it 'returns the url when no version' do
      q = FHIR::Questionnaire.new(url: 'http://example.com/q', status: 'draft')
      expect(sim.send(:canonical_url_for_resource, q)).to eq('http://example.com/q')
    end

    it 'returns url|version when version is present' do
      q = FHIR::Questionnaire.new(url: 'http://example.com/q', version: '1.0', status: 'draft')
      expect(sim.send(:canonical_url_for_resource, q)).to eq('http://example.com/q|1.0')
    end

    it 'returns nil when url is blank' do
      expect(sim.send(:canonical_url_for_resource, FHIR::Questionnaire.new(status: 'draft'))).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # adaptive_questionnaire?
  # ---------------------------------------------------------------------------

  describe '#adaptive_questionnaire?' do
    it 'returns true for a questionnaire with the adaptive extension (valueBoolean: true)' do
      q = make_questionnaire(url: 'http://example.com/q', adaptive: true)
      expect(sim.send(:adaptive_questionnaire?, q)).to be true
    end

    it 'returns true for a questionnaire with the adaptive extension (valueUrl present)' do
      q = FHIR::Questionnaire.new(
        status: 'draft',
        extension: [FHIR::Extension.new(
          url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueUrl: 'http://adaptive.example.com'
        )]
      )
      expect(sim.send(:adaptive_questionnaire?, q)).to be true
    end

    it 'returns false for a questionnaire without the adaptive extension' do
      expect(sim.send(:adaptive_questionnaire?, FHIR::Questionnaire.new(status: 'draft'))).to be false
    end

    it 'returns false for a non-Questionnaire resource' do
      expect(sim.send(:adaptive_questionnaire?, FHIR::Patient.new)).to be false
    end
  end

  # ---------------------------------------------------------------------------
  # next_question_base_url
  # ---------------------------------------------------------------------------

  describe '#next_question_base_url' do
    let(:fallback_url) { 'https://payer.example.com/fhir' }

    it 'returns valueUrl from the adaptive extension when present' do
      q = FHIR::Questionnaire.new(
        status: 'draft',
        extension: [FHIR::Extension.new(
          url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueUrl: 'https://adaptive.example.com'
        )]
      )
      expect(sim.send(:next_question_base_url, q, fallback_url)).to eq('https://adaptive.example.com')
    end

    it 'falls back to fhir_base_url when the extension uses valueBoolean instead of valueUrl' do
      q = make_questionnaire(url: 'http://example.com/q', adaptive: true)
      expect(sim.send(:next_question_base_url, q, fallback_url)).to eq(fallback_url)
    end

    it 'falls back to fhir_base_url when there is no adaptive extension' do
      q = FHIR::Questionnaire.new(status: 'draft')
      expect(sim.send(:next_question_base_url, q, fallback_url)).to eq(fallback_url)
    end
  end

  # ---------------------------------------------------------------------------
  # extract_response_package_bundles
  # ---------------------------------------------------------------------------

  describe '#extract_response_package_bundles' do
    it 'returns bundles from a successful Parameters response' do
      bundle = FHIR::Bundle.new(type: 'collection')
      params = FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)]
      )
      response = MockFhirResponse.new(200, params.to_json)
      expect(sim.send(:extract_response_package_bundles, response)).to eq([bundle])
    end

    it 'returns [] for a non-2xx response' do
      response = MockFhirResponse.new(400, {}.to_json)
      expect(sim.send(:extract_response_package_bundles, response)).to eq([])
    end

    it 'returns [] when the body is not a Parameters resource' do
      response = MockFhirResponse.new(200, FHIR::Bundle.new.to_json)
      expect(sim.send(:extract_response_package_bundles, response)).to eq([])
    end

    it 'ignores non-Bundle packagebundle parameters' do
      params = FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: FHIR::Patient.new)]
      )
      response = MockFhirResponse.new(200, params.to_json)
      expect(sim.send(:extract_response_package_bundles, response)).to eq([])
    end
  end

  # ---------------------------------------------------------------------------
  # extract_next_question_response_form
  # ---------------------------------------------------------------------------

  describe '#extract_next_question_response_form' do
    it 'returns a bare QuestionnaireResponse directly' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress')
      response = MockFhirResponse.new(200, qr.to_json)
      expect(sim.send(:extract_next_question_response_form, response)).to be_a(FHIR::QuestionnaireResponse)
    end

    it 'extracts QuestionnaireResponse from a Parameters return parameter' do
      qr = FHIR::QuestionnaireResponse.new(status: 'in-progress')
      params = FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(name: 'return', resource: qr)]
      )
      response = MockFhirResponse.new(200, params.to_json)
      expect(sim.send(:extract_next_question_response_form, response)).to be_a(FHIR::QuestionnaireResponse)
    end

    it 'returns nil when Parameters has no matching return parameter' do
      params = FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(name: 'other', resource: FHIR::Patient.new)]
      )
      response = MockFhirResponse.new(200, params.to_json)
      expect(sim.send(:extract_next_question_response_form, response)).to be_nil
    end

    it 'returns nil for invalid JSON' do
      response = MockFhirResponse.new(200, 'not json')
      expect(sim.send(:extract_next_question_response_form, response)).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # find_template_for_canonical
  # ---------------------------------------------------------------------------

  describe '#find_template_for_canonical' do
    let(:canonical) { 'http://example.com/q' }
    let(:template) do
      FHIR::QuestionnaireResponse.new(
        status: 'in-progress',
        contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
      )
    end

    it 'returns the matching template' do
      expect(sim.send(:find_template_for_canonical, canonical, [template])).to eq(template)
    end

    it 'returns nil when no template matches' do
      expect(sim.send(:find_template_for_canonical, 'http://other.com/q', [template])).to be_nil
    end

    it 'returns nil without crashing when templates is nil' do
      expect { sim.send(:find_template_for_canonical, canonical, nil) }.to_not raise_error
      expect(sim.send(:find_template_for_canonical, canonical, nil)).to be_nil
    end

    it 'returns nil without crashing when templates is empty' do
      expect(sim.send(:find_template_for_canonical, canonical, [])).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # collect_adaptive_questionnaire_details
  # ---------------------------------------------------------------------------

  describe '#collect_adaptive_questionnaire_details' do
    let(:canonical) { 'http://example.com/adaptive-q' }
    let(:adaptive_q) { make_questionnaire(url: canonical, adaptive: true) }
    let(:template) do
      FHIR::QuestionnaireResponse.new(
        status: 'in-progress',
        item: [qr_item('Q1', answer_value: 'answer')],
        contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
      )
    end
    let(:bundle) do
      FHIR::Bundle.new(type: 'collection', entry: [FHIR::Bundle::Entry.new(resource: adaptive_q)])
    end

    it 'returns a detail hash with questionnaire, template, and a blank QR' do
      result = sim.send(:collect_adaptive_questionnaire_details, bundle, [template])
      expect(result[:questionnaire]).to eq(adaptive_q)
      expect(result[:template]).to eq(template)
      expect(result[:questionnaire_response].item).to be_empty
    end

    it 'uses the QR from the bundle when present' do
      initial_qr = FHIR::QuestionnaireResponse.new(status: 'in-progress')
      bundle_with_qr = FHIR::Bundle.new(type: 'collection', entry: [
                                          FHIR::Bundle::Entry.new(resource: adaptive_q),
                                          FHIR::Bundle::Entry.new(resource: initial_qr)
                                        ])
      result = sim.send(:collect_adaptive_questionnaire_details, bundle_with_qr, [template])
      expect(result[:questionnaire_response]).to eq(initial_qr)
    end

    it 'returns nil and records an error when questionnaire has no canonical url' do
      no_url_bundle = FHIR::Bundle.new(
        type: 'collection',
        entry: [FHIR::Bundle::Entry.new(resource: FHIR::Questionnaire.new(status: 'draft'))]
      )
      result = sim.send(:collect_adaptive_questionnaire_details, no_url_bundle, [template])
      expect(result).to be_nil
      expect(sim.messages).to include(hash_including(level: 'error'))
    end

    it 'returns nil and records an error when no matching template exists' do
      result = sim.send(:collect_adaptive_questionnaire_details, bundle, [])
      expect(result).to be_nil
      expect(sim.messages).to include(hash_including(level: 'error'))
    end

    it 'returns nil and records an error when templates is nil' do
      result = sim.send(:collect_adaptive_questionnaire_details, bundle, nil)
      expect(result).to be_nil
      expect(sim.messages).to include(hash_including(level: 'error'))
    end
  end

  # ---------------------------------------------------------------------------
  # extract_adaptive_questionnaires
  # ---------------------------------------------------------------------------

  describe '#extract_adaptive_questionnaires' do
    let(:canonical) { 'http://example.com/adaptive-q' }
    let(:adaptive_bundle) do
      FHIR::Bundle.new(type: 'collection', entry: [
                         FHIR::Bundle::Entry.new(resource: make_questionnaire(url: canonical, adaptive: true))
                       ])
    end
    let(:static_bundle) do
      FHIR::Bundle.new(type: 'collection', entry: [
                         FHIR::Bundle::Entry.new(resource: make_questionnaire(url: 'http://example.com/static-q'))
                       ])
    end
    let(:template) do
      FHIR::QuestionnaireResponse.new(
        status: 'in-progress',
        contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
      )
    end

    it 'filters out non-adaptive bundles' do
      expect(sim.send(:extract_adaptive_questionnaires, [static_bundle], [template])).to be_empty
    end

    it 'returns detail hashes for adaptive bundles with a matching template' do
      result = sim.send(:extract_adaptive_questionnaires, [adaptive_bundle], [template])
      expect(result.length).to eq(1)
      expect(result.first).to be_a(Hash)
    end

    it 'omits nil results when no matching template exists (no crash)' do
      result = sim.send(:extract_adaptive_questionnaires, [adaptive_bundle], [])
      expect(result).to be_empty
    end

    it 'does not crash and omits nil results when templates is nil' do
      expect { sim.send(:extract_adaptive_questionnaires, [adaptive_bundle], nil) }.to_not raise_error
      expect(sim.send(:extract_adaptive_questionnaires, [adaptive_bundle], nil)).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # request_adaptive_questionnaire_using_next_question (loop behavior)
  # ---------------------------------------------------------------------------

  describe '#request_adaptive_questionnaire_using_next_question' do
    let(:canonical) { 'http://example.com/adaptive-q' }
    let(:adaptive_q) { make_questionnaire(url: canonical, adaptive: true) }
    let(:template) do
      FHIR::QuestionnaireResponse.new(
        status: 'in-progress',
        item: [qr_item('Q1', answer_value: 'my-answer')],
        contained: [FHIR::Questionnaire.new(url: canonical, status: 'draft')]
      )
    end
    let(:initial_qr) { qr_with_contained(make_questionnaire(url: canonical)) }
    let(:detail) { { questionnaire: adaptive_q, questionnaire_response: initial_qr, template: } }

    def nq_response(status:, items: [])
      qr = FHIR::QuestionnaireResponse.new(
        status:,
        contained: [make_questionnaire(url: canonical, items:)]
      )
      MockFhirResponse.new(200, qr.to_json)
    end

    it 'records no warning when the server returns a completed form' do
      sim.queue_response(nq_response(status: 'completed', items: [q_item('Q1')]))
      sim.send(:request_adaptive_questionnaire_using_next_question, detail, 'https://payer.example.com')
      expect(sim.messages).to_not include(hash_including(level: 'warning'))
    end

    it 'records a warning when the loop ends without the form completing' do
      # First response: Q1 added (new items present, answered in template)
      sim.queue_response(nq_response(status: 'in-progress', items: [q_item('Q1')]))
      # Second response: same Q1, no new items → loop breaks without completion
      sim.queue_response(nq_response(status: 'in-progress', items: [q_item('Q1')]))
      sim.send(:request_adaptive_questionnaire_using_next_question, detail, 'https://payer.example.com')
      expect(sim.messages).to include(hash_including(level: 'warning'))
    end

    it 'records a warning when the server returns a non-2xx response' do
      sim.queue_response(MockFhirResponse.new(500, 'error'))
      sim.send(:request_adaptive_questionnaire_using_next_question, detail, 'https://payer.example.com')
      expect(sim.recorded_requests.count).to eq(1)
      expect(sim.messages).to include(hash_including(level: 'warning'))
    end

    it 'makes multiple next-question requests until no new items remain' do
      sim.queue_response(nq_response(status: 'in-progress', items: [q_item('Q1')]))
      sim.queue_response(nq_response(status: 'in-progress', items: [q_item('Q1')]))
      sim.send(:request_adaptive_questionnaire_using_next_question, detail, 'https://payer.example.com')
      expect(sim.recorded_requests.count).to eq(2)
    end

    it 'uses the questionnaire adaptive extension URL for next-question requests when present' do
      adaptive_url = 'https://adaptive.example.com'
      q_with_url = FHIR::Questionnaire.new(
        url: canonical, status: 'draft',
        extension: [FHIR::Extension.new(
          url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueUrl: adaptive_url
        )]
      )
      detail_with_url = { questionnaire: q_with_url, questionnaire_response: initial_qr, template: }
      sim.queue_response(nq_response(status: 'completed'))
      sim.send(:request_adaptive_questionnaire_using_next_question, detail_with_url, 'https://payer.example.com')
      expect(sim.recorded_requests.first[:url]).to start_with(adaptive_url)
    end
  end
end
