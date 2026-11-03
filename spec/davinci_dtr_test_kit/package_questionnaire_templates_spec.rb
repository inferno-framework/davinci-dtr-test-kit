require 'davinci_dtr_test_kit/full_ehr/v2.2.0/package_questionnaire_templates'

RSpec.describe DaVinciDTRTestKit::PackageQuestionnaireTemplates do
  subject(:host) do
    host_class = Class.new do
      include DaVinciDTRTestKit::PackageQuestionnaireTemplates

      attr_accessor :next_question_templates
    end
    host_class.new.tap { |instance| instance.next_question_templates = [template] }
  end

  let(:template_url) { 'https://example.org/Questionnaire/adaptive' }
  let(:use_template_url) { DaVinciDTRTestKit::InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL }
  let(:include_in_package_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUDE_IN_PACKAGE_URL }
  let(:adaptive_extension) do
    { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
      valueBoolean: true }
  end
  let(:in_package) { [{ url: include_in_package_url, valueBoolean: true }] }

  # Group G holds a marked and an unmarked child; Q2 is marked at the top level; Q3 is unmarked.
  let(:template) do
    FHIR.from_contents({
      resourceType: 'Questionnaire',
      id: 'template-id',
      url: template_url,
      version: '1.0',
      status: 'draft',
      title: 'Template Title',
      extension: [adaptive_extension],
      item: [
        { linkId: 'G', type: 'group', item: [
          { linkId: 'G.1', type: 'string', extension: in_package },
          { linkId: 'G.2', type: 'string' }
        ] },
        { linkId: 'Q2', type: 'string', extension: in_package },
        { linkId: 'Q3', type: 'string' }
      ]
    }.to_json)
  end

  def placeholder(canonical = template_url, **elements)
    FHIR::Questionnaire.new(extension: [FHIR::Extension.new(url: use_template_url, valueCanonical: canonical)],
                            **elements)
  end

  def package_parameters(*resources)
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(type: 'collection',
                                     entry: resources.map { |resource| FHIR::Bundle::Entry.new(resource:) })
        )
      ]
    )
  end

  def link_ids(items)
    items.map { |item| [item.linkId, link_ids(item.item)] }
  end

  describe '#expand_template_placeholders' do
    it 'replaces a placeholder with the template, keeping marked items and the items that contain them' do
      parameters = package_parameters(placeholder)
      host.expand_template_placeholders(parameters)

      expanded = parameters.parameter.first.resource.entry.first.resource
      expect(expanded.url).to eq(template_url)
      expect(expanded.title).to eq('Template Title')
      expect(link_ids(expanded.item)).to eq([['G', [['G.1', []]]], ['Q2', []]])
    end

    it 'gives elements set on the placeholder precedence and adds its other extensions' do
      other_extension = FHIR::Extension.new(url: 'https://example.org/other', valueString: 'kept')
      parameters = package_parameters(placeholder(id: 'placeholder-id'))
      parameters.parameter.first.resource.entry.first.resource.extension << other_extension
      host.expand_template_placeholders(parameters)

      expanded = parameters.parameter.first.resource.entry.first.resource
      expect(expanded.id).to eq('placeholder-id')
      expect(expanded.extension.map(&:url)).to contain_exactly(adaptive_extension[:url], 'https://example.org/other')
    end

    it 'does not repeat extensions that the placeholder shares with the template' do
      parameters = package_parameters(placeholder)
      parameters.parameter.first.resource.entry.first.resource.extension << FHIR::Extension.new(adaptive_extension)
      host.expand_template_placeholders(parameters)

      expanded = parameters.parameter.first.resource.entry.first.resource
      expect(expanded.extension.map(&:url)).to eq([adaptive_extension[:url]])
    end

    it 'keeps all the children of a marked group that has no marked children' do
      template.item << FHIR::Questionnaire::Item.new(
        linkId: 'G2', type: 'group', extension: in_package,
        item: [{ linkId: 'G2.1', type: 'string' }, { linkId: 'G2.2', type: 'string' }]
      )
      parameters = package_parameters(placeholder)
      host.expand_template_placeholders(parameters)

      expanded = parameters.parameter.first.resource.entry.first.resource
      expect(link_ids(expanded.item)).to eq([['G', [['G.1', []]]], ['Q2', []],
                                             ['G2', [['G2.1', []], ['G2.2', []]]]])
    end

    it 'expands placeholders contained in a QuestionnaireResponse' do
      response = FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [placeholder])
      parameters = package_parameters(response)
      host.expand_template_placeholders(parameters)

      contained = parameters.parameter.first.resource.entry.first.resource.contained.first
      expect(contained.id).to eq('template-id')
      expect(contained.url).to eq(template_url)
    end

    it 'matches a versioned canonical' do
      parameters = package_parameters(placeholder("#{template_url}|1.0"))
      host.expand_template_placeholders(parameters)

      expect(parameters.parameter.first.resource.entry.first.resource.url).to eq(template_url)
    end

    it 'raises MissingTemplateError when no template matches' do
      parameters = package_parameters(placeholder("#{template_url}|2.0"))

      expect { host.expand_template_placeholders(parameters) }
        .to raise_error(described_class::MissingTemplateError, /#{Regexp.quote(template_url)}\|2\.0/)
    end

    it 'leaves Questionnaires without the extension unchanged' do
      questionnaire = FHIR::Questionnaire.new(url: 'https://example.org/Questionnaire/static', status: 'draft')
      parameters = package_parameters(questionnaire)
      host.expand_template_placeholders(parameters)

      expect(parameters.parameter.first.resource.entry.first.resource).to equal(questionnaire)
    end
  end

  describe '#template_placeholder_canonicals' do
    it 'finds placeholders at the top level and contained in QuestionnaireResponses' do
      response = FHIR::QuestionnaireResponse.new(status: 'in-progress',
                                                 contained: [placeholder("#{template_url}|1.0")])
      parameters = package_parameters(placeholder, response)

      expect(host.template_placeholder_canonicals(parameters)).to eq([template_url, "#{template_url}|1.0"])
    end
  end
end
