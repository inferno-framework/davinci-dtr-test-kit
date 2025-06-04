RSpec.describe DaVinciDTRTestKit::DTRFullEHRQuestionnaireResponseCorrectnessTest do
  let(:suite_id) { :dtr_full_ehr }
  let(:custom_questionnaire_package_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_package.json'))
  end
  let(:questionnaire_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_response_conformant.json'))
  end
  let(:bad_questionnaire_response) do
    File.read(File.join(__dir__, '..', 'fixtures', 'dinner_questionnaire_response_missing_answers.json'))
  end

  context 'when custom response workflow' do
    let(:runnable) do
      Class.new(described_class) do
        input :custom_questionnaire_package_response
        input :questionnaire_response, optional: true
      end
    end

    it 'passes if all required questions are answered and all questionnaire response items have an origin.source' do
      result = run(runnable, test_session, questionnaire_response:, custom_questionnaire_package_response:)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'skips if no questionnaire_response provided for validation' do
      result = run(runnable, test_session, custom_questionnaire_package_response:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/QuestionnaireResponse input was blank/)
    end

    it 'skips if the questionnaire referenced in the QR is not in the provided custom package response' do
      result = run(
        runnable, test_session, questionnaire_response:, custom_questionnaire_package_response: FHIR::Bundle.new.to_json
      )
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/Couldn't find Questionnaire/)
    end

    it 'fails if a required answer is missing or all QR items do not have an origin.source' do
      result = run(
        runnable, test_session, questionnaire_response: bad_questionnaire_response,
                                custom_questionnaire_package_response:
      )
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/QuestionnaireResponse is not correct/)
    end
  end
end
