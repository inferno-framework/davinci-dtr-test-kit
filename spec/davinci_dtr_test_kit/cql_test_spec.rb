RSpec.describe DaVinciDTRTestKit::CQLTest do
  let(:test) { Class.new { extend DaVinciDTRTestKit::CQLTest, Inferno::DSL::Assertions } }

  describe 'given a bad response' do
    let(:output_params_no_lib) do
      FHIR.from_contents(File.read(File.join(
                                     __dir__, '..',
                                     'fixtures', 'questionnaire_package_output_params_conformant.json'
                                   )))
    end

    it 'nothing should raise exception' do
      expect { test.check_libraries(nil) }.to raise_error(
        Inferno::Exceptions::AssertionException, /Response is null or not a valid type./
      )
    end

    it 'no libraries should raise exception' do
      expect { test.check_libraries(output_params_no_lib) }.to raise_error(
        Inferno::Exceptions::AssertionException, /No Libraries found./
      )
    end
  end

  describe 'given a good response' do
    let(:output_params) do
      FHIR.from_contents(File.read(File.join(
                                     __dir__, '..',
                                     'fixtures', 'questionnaire_package_output_params_non_conformant.json'
                                   )))
    end

    it 'test should pass' do
      expect(test.check_libraries(output_params)).to equal(nil)
    end
  end
end
