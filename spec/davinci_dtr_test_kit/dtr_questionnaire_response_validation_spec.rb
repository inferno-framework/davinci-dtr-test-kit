RSpec.describe DaVinciDTRTestKit::DTRQuestionnaireResponseValidation, :runnable do
  let(:suite_id) { :dtr_smart_app }

  # rubocop:disable RSpec/EmptyExampleGroup
  describe '#validate_questionnaire_pre_population' do
    let(:test) do
      Class.new(Inferno::Test) do
        include DaVinciDTRTestKit::DTRQuestionnaireResponseValidation

        uses_request :questionnaire_response_save
        run do
          validate_questionnaire_pre_population(request)
        end
      end
    end
    let(:questionnaire_response_url) { 'http://example.org/fhir/QuestionnaireResponse' }
    let(:conformant_questionnaire_response) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_conformant.json'))
    end

    before do
      Inferno::Repositories::Tests.new.insert(test)
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_response_url).and_return(questionnaire_response_url)
      )
    end

    # conformance validation moved to another test - need tests for it
    # it 'passes with a valid QuestionnaireResponse' do
    #  allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
    #  repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
    #                        request_body: conformant_questionnaire_response, test_session_id: test_session.id)
    #  result = run(test)
    #  expect(result.result).to eq('pass')
    # end

    # conformance validation moved to another test - need tests for it
    # it 'fails with a QuestionnaireResponse that does not conform to the proifle' do
    #  allow_any_instance_of(test).to receive(:assert_valid_resource).and_raise(Inferno::Exceptions::AssertionException)
    #  repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
    #                        request_body: conformant_questionnaire_response, test_session_id: test_session.id)
    #  result = run(test)
    #  expect(result.result).to eq('fail')
    # end

    # context('with a QuestionnaireResponse that has not been fully pre-populated with CQL execution') do
    #   let(:questionnaire_response_cql_answer_missing) do
    #     File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_cql_answer_missing.json'))
    #   end

    #   it 'fails' do
    #     allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
    #     repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
    #                           request_body: questionnaire_response_cql_answer_missing,
    #                           test_session_id: test_session.id)
    #     result = run(test)
    #     expect(result.result).to eq('fail')
    #   end
    # end

    # context('with a QuestionnaireResponse with an origin.source of manual when it should be auto or override') do
    #   let(:questionnaire_response_incorrect_origin) do
    #     File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_incorrect_origin.json'))
    #   end

    #   it 'fails' do
    #     allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
    #     repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
    #                           request_body: questionnaire_response_incorrect_origin, test_session_id: test_session.id)
    #     result = run(test)
    #     expect(result.result).to eq('fail')
    #   end
    # end

    # these tests removed, but will be restored later in another place
    # context('with a QuestionnaireResponse with an unretrieved dataRequirement') do
    #   let(:questionnaire_response_missing_data_requirement) do
    #     File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_missing_data_requirement.json'))
    #   end

    #   it 'fails' do
    #     allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
    #     repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
    #                           request_body: questionnaire_response_missing_data_requirement,
    #                           test_session_id: test_session.id)
    #     result = run(test)
    #     expect(result.result).to eq('fail')
    #   end
    # end
  end
  # rubocop:enable RSpec/EmptyExampleGroup
end
