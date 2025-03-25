module DaVinciDTRTestKit
  class DTRQuestionnaireMustSupportGroup < Inferno::TestGroup
    id :dtr_full_ehr_questionnaire_ms
    title 'Demonstrate Element Support'
    description %()

    group do
      run_as_group
      title 'Static Questionnaires Element Support'

      group do
        title 'Retrieving the Static Questionnaires for must support validation'
      end

      group do
        title '[USER INPUT VALIDATION] Static Questionnaires Must Support'
        test 'All must support elements are provided in the static Questionnaire resources provided' do
        end
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaires'
        test 'Attest rendering and filling of provided static Questionnaire resources' do
        end
      end

      group do
        title 'Attestation: QuestionnaireResponse Completion and Storage'
      end
    end

    group do
      run_as_group
      title 'Adaptive Questionnaires Element Support'

      group do
        title 'Retrieving the Adaptive Questionnaires for must support validation'
      end

      group do
        title '[USER INPUT VALIDATION] Adaptive Questionnaires Must Support'
        test 'All must support elements are provided in the adaptive Questionnaire resources provided' do
        end
      end

      group do
        title 'Attestation: Filling Out the Static Questionnaire'
        test 'Attest rendering and filling of provided adaptive Questionnaire resources' do
        end
      end

      group do
        title 'Attestation: QuestionnaireResponse Completion and Storage'
      end
    end
  end
end
