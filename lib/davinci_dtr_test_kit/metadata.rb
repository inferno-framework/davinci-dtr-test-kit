require_relative 'version'

module DaVinciDTRTestKit
  class Metadata < Inferno::TestKit
    id :davinci_dtr_test_kit
    title 'Da Vinci Documentation Templates and Rules (DTR) Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Documentation Templates and Rules (DTR) Test Kit validates
      the conformance of both provider and payer implementations to
      the Da Vinci DTR Implementation Guide. It includes suites covering the
      following versions:
      - [Da Vinci Documentation Templates and Rules (DTR) v2.0.1](https://hl7.org/fhir/us/davinci-dtr/STU2/)
      - [Da Vinci Documentation Templates and Rules (DTR) v2.2.0](https://hl7.org/fhir/us/davinci-dtr/2.2.0/)

      <!-- break -->

      ## Status

      These tests are a **DRAFT** intended to allow DTR implementers to perform
      preliminary checks of their implementations against the DTR IG requirements and
      provide feedback on the tests. Future versions of these tests may validate other
      requirements and may change how these are tested.

      Details on the IG requirements that underlie this test kit can be
      found in the [Specification Requirements display within the testing UI](https://inferno-framework.github.io/docs/user-interface.html#specification-requirements)
      and other artifacts of Inferno's [requirements tracking tools](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html).

      ## Additional Details

      Additional details about design, scope, and limitations of the suites within this
      test kit can be found on the [DTR Test Kit Wiki](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki).

      ## Reporting Issues

      Please report any issues with this set of tests in the [GitHub
      Issues](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
      section of the
      [open-source code repository](https://github.com/inferno-framework/davinci-dtr-test-kit).
    DESCRIPTION
    suite_ids [:dtr_payer_server, :dtr_smart_app, :dtr_full_ehr, :dtr_light_ehr,
               :dtr_payer_server_v220, :dtr_full_ehr_v220]
    tags ['Da Vinci', 'DTR']
    last_updated LAST_UPDATED
    version VERSION
    maturity 'Low'
    authors ['Karl Naden', 'Tom Strassner', 'Robert Passas', 'Vanessa Fotso', 'Elsa Perelli']
    repo 'https://github.com/inferno-framework/davinci-dtr-test-kit'
  end
end
