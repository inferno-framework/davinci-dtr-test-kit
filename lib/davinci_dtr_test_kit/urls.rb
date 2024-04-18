# frozen_string_literal: true

module DaVinciDTRTestKit
  TOKEN_PATH = '/mock_auth/token'
  QUESTIONNAIRE_PACKAGE_PATH = '/fhir/Questionnaire/$questionnaire-package'
  NEXT_PATH = '/fhir/Questionnaire/$next-question'
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'

  module URLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
    end

    def token_url
      @token_url ||= base_url + TOKEN_PATH
    end

    def questionnaire_package_url
      @questionnaire_package_url ||= base_url + QUESTIONNAIRE_PACKAGE_PATH
    end

    def next_url
      @next_url ||= base_url + NEXT_PATH
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
