# frozen_string_literal: true

module DaVinciDTRTestKit
  FHIR_BASE_PATH = '/fhir'
  METADATA_PATH = "#{FHIR_BASE_PATH}/metadata".freeze
  SMART_CONFIG_PATH = "#{FHIR_BASE_PATH}/.well-known/smart-configuration".freeze
  OPENID_CONFIG_PATH = "#{FHIR_BASE_PATH}/.well-known/openid-configuration".freeze
  JKWS_PATH = "#{FHIR_BASE_PATH}/.well-known/jwks.json".freeze
  EHR_AUTHORIZE_PATH = "#{FHIR_BASE_PATH}/mock_ehr_auth/authorize".freeze
  EHR_TOKEN_PATH = "#{FHIR_BASE_PATH}/mock_ehr_auth/token".freeze
  PAYER_TOKEN_PATH = "#{FHIR_BASE_PATH}/mock_payer_auth/token".freeze
  QUESTIONNAIRE_PACKAGE_PATH = "#{FHIR_BASE_PATH}/Questionnaire/$questionnaire-package".freeze
  NEXT_PATH = "#{FHIR_BASE_PATH}/Questionnaire/$next-question".freeze
  QUESTIONNAIRE_RESPONSE_PATH = "#{FHIR_BASE_PATH}/QuestionnaireResponse".freeze
  FHIR_RESOURCE_PATH = "#{FHIR_BASE_PATH}/:resource/:id".freeze
  FHIR_SEARCH_PATH = "#{FHIR_BASE_PATH}/:resource".freeze
  SUPPORTED_PAYER_PATH = '/:tester_url_id/supported-payers'
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'
  AUTH_SERVER_PATH = '/auth'
  SMART_DISCOVERY_PATH = "#{FHIR_BASE_PATH}/.well-known/smart-configuration".freeze
  UDAP_DISCOVERY_PATH = "#{FHIR_BASE_PATH}/.well-known/udap".freeze
  TOKEN_PATH = "#{AUTH_SERVER_PATH}/token".freeze
  REGISTRATION_PATH = "#{AUTH_SERVER_PATH}/register".freeze

  module URLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
    end

    def fhir_base_url
      @fhir_base_url ||= base_url + FHIR_BASE_PATH
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

    def supported_payer_url(unique_url_id)
      @supported_payer_url ||= base_url + SUPPORTED_PAYER_PATH.gsub(':tester_url_id', unique_url_id)
    end

    def resume_pass_url
      @resume_pass_url ||= base_url + RESUME_PASS_PATH
    end

    def resume_fail_url
      @resume_fail_url ||= base_url + RESUME_FAIL_PATH
    end

    def udap_discovery_url
      @udap_discovery_url ||= base_url + UDAP_DISCOVERY_PATH
    end

    def token_url
      @token_url ||= base_url + TOKEN_PATH
    end

    def registration_url
      @registration_url ||= base_url + REGISTRATION_PATH
    end

    def suite_id
      self.class.suite.id
    end
  end
end
