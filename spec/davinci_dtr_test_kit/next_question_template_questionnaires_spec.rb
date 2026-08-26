require 'spec_helper'
require 'davinci_dtr_test_kit/full_ehr/v2.2.0/next_question_template_questionnaires'

RSpec.describe DaVinciDTRTestKit::NextQuestionTemplateQuestionnaires do
  subject(:host) { Class.new { include DaVinciDTRTestKit::NextQuestionTemplateQuestionnaires }.new }

  let(:questionnaire_json) { FHIR::Questionnaire.new(status: 'draft').to_json }
  let(:other_questionnaire_json) { FHIR::Questionnaire.new(status: 'draft', url: 'urn:other').to_json }

  describe '#questionnaires_from_template_value' do
    it 'wraps a single Questionnaire in a list' do
      questionnaires = host.questionnaires_from_template_value(questionnaire_json)

      expect(questionnaires.length).to eq(1)
      expect(questionnaires.first).to be_a(FHIR::Questionnaire)
    end

    it 'returns every Questionnaire in a JSON array' do
      value = [JSON.parse(questionnaire_json), JSON.parse(other_questionnaire_json)].to_json

      questionnaires = host.questionnaires_from_template_value(value)

      expect(questionnaires.length).to eq(2)
      expect(questionnaires).to all(be_a(FHIR::Questionnaire))
    end

    it 'silently discards array entries that are not Questionnaires, keeping the valid ones' do
      value = [JSON.parse(questionnaire_json), { resourceType: 'Bundle', type: 'collection' }].to_json

      questionnaires = host.questionnaires_from_template_value(value)

      expect(questionnaires.length).to eq(1)
      expect(questionnaires.first).to be_a(FHIR::Questionnaire)
    end

    it 'returns an empty list when the value is a single non-Questionnaire resource' do
      value = { resourceType: 'Bundle', type: 'collection' }.to_json

      expect(host.questionnaires_from_template_value(value)).to eq([])
    end

    it 'returns an empty list for an empty array' do
      expect(host.questionnaires_from_template_value('[]')).to eq([])
    end

    it 'raises JSON::ParserError for invalid JSON' do
      expect { host.questionnaires_from_template_value('not valid json') }.to raise_error(JSON::ParserError)
    end
  end

  describe '#parse_template_questionnaire' do
    it 'returns the parsed Questionnaire for valid Questionnaire JSON' do
      parsed = host.parse_template_questionnaire(JSON.parse(questionnaire_json))

      expect(parsed).to be_a(FHIR::Questionnaire)
    end

    it 'returns nil for a non-Questionnaire resource' do
      expect(host.parse_template_questionnaire({ resourceType: 'Bundle', type: 'collection' })).to be_nil
    end

    it 'returns nil rather than raising when given something that cannot be converted to FHIR' do
      expect(host.parse_template_questionnaire('not a hash')).to be_nil
    end
  end
end
