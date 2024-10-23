# frozen_string_literal: true

module DaVinciDTRTestKit
  SMART_CONFIG_PATH = '/fhir/.well-known/smart-configuration'
  JKWS_PATH = '/fhir/.well-known/jwks.json'
  EHR_AUTHORIZE_PATH = '/mock_ehr_auth/authorize'
  EHR_TOKEN_PATH = '/mock_ehr_auth/token'
  PAYER_TOKEN_PATH = '/mock_payer_auth/token'
  QUESTIONNAIRE_PACKAGE_PATH = '/fhir/Questionnaire/$questionnaire-package'
  NEXT_PATH = '/fhir/Questionnaire/$next-question'
  QUESTIONNAIRE_RESPONSE_PATH = '/fhir/QuestionnaireResponse'
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'
  FHIR_RESOURCE_PATH = '/fhir/:resource/:id'
  FHIR_SEARCH_PATH = '/fhir/:resource'

  module URLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
    end

    def ehr_authorize_url
      @ehr_authorize_url ||= base_url + EHR_AUTHORIZE_PATH
    end

    def ehr_token_url
      @ehr_token_url ||= base_url + EHR_TOKEN_PATH
    end

    def payer_token_url
      @payer_token_url ||= base_url + PAYER_TOKEN_PATH
    end

    def questionnaire_package_url
      @questionnaire_package_url ||= base_url + QUESTIONNAIRE_PACKAGE_PATH
    end

    def next_url
      @next_url ||= base_url + NEXT_PATH
    end

    def questionnaire_response_url
      @questionnaire_response_url ||= base_url + QUESTIONNAIRE_RESPONSE_PATH
    end

    def fhir_base_url
      @fhir_base_url ||= "#{base_url}/fhir"
    end

    def resume_pass_url
      @resume_pass_url ||= base_url + RESUME_PASS_PATH
    end

    def resume_fail_url
      @resume_fail_url ||= base_url + RESUME_FAIL_PATH
    end

    def suite_id
      self.class.suite.id
    end
  end
end
