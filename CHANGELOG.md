# v0.16.0
## Breaking Change
This release updates the Da Vinci DTR Test Kit to use AuthInfo rather than
OAuthCredentials for storing auth information. As a result of this change, any
test kits which rely on this test kit will need to be updated to use AuthInfo
rather than OAuthCredentials inputs.

* FI-3746: Use AuthInfo by @Jammjammjamm in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/65

# v0.15.2
* Remove internal presets from gem by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/64

# v0.15.1
* FI-3463: DTR Light EHR: test supported payer endpoint by @degradification in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/42
* Fi-3766: Add Full DTR EHR verifies requirements by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/57
* FI-3800: Add Payer Server verifies_requirements by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/59
* Fix typo in metadata title by @Shaumik-Ashraf in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/61


# v0.15.0
* **Ruby Version Update:** Upgraded Ruby to `3.3.6`.
* **Inferno Core Update:** Bumped to version `0.6`.
* **Gemspec Updates:**
  * Switched to `git` for specifying files.
  * Added `presets` to the gem package.
  * Updated any test kit dependencies
* **Test Kit Metadata:** Implemented Test Kit metadata for Inferno Platform.
* **Environment Updates:** Updated Ruby version in the Dockerfile and GitHub Actions workflow.
* FI-3509: Metadata OAuth URIs by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/43
* FI-3232: Add DTR Specific SMART App launch tests by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/45
* Migrate gitlab changes by @vanessuniq in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/50
* Fi 3515: mustSupports tests for Light DTR EHR profiles by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/52
* FI-3648: Add Spec for Shared Tests and Implement Features for the Failing Tests by @vanessuniq in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/49
* FI-3739: Add Light DTR EHR verifies  requirements  by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/54
* Shorten ids by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/55
* FI-3473: Fix INFERNO_HOST Value for Prod by @vanessuniq in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/53

# v0.14.1
* Make us_core_test_kit and tls_test_kit dependencies relative

# v0.14.0
* FI-3222: DTR Client Tests: Use Random Number for Attestation Continuation Links by @degradification in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/20
* FI-3299: Fix Questionnaire Package verification in Payer suite by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/29
* Fix typo in bearer token by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/30
* Add USCore 3.1.1 test group, CRD profile tests by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/26
* Add create and update tests for QuestionnaireResponse and Task by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/31
* FI-3154: Full EHR Adaptive Questionnaire Tests by @vanessuniq in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/22
* FI-3514: Bug fix for inputs for different workflows by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/34
* FI-3435: Documentation for DTR Light EHR release by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/35
* FI-3300: Suite Endpoints by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/37
* FI-3520: update docs to account for new adaptive tests by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/38

# v0.13.0
* Fix wording in SMART App Launch description by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/18
* FI-3069: Full EHR QuestionnaireResponse verification by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/19
* Fi-3231: Add SMART app tests to Light DTR EHR suite by @elsaperelli in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/21
* FI-3270: CI, Rubocop by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/23
* FI-3161: ID Token by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/24
* FI-3410: Update inferno core requirement by @Jammjammjamm in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/25

# v0.12.0
* rm extra assert by @rpassas in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/12
* Full ehr tests by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/15
* FI-3094: Example JWT fix by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/16
* Release 0.12.0 by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/17

# v0.11.1
* Pre connectathon fixes by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/14

# v0.11.0
* FI-2732: Add SMART App Launch capability by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/9

# v0.10.0
* Postman Tweaks by @tstrass in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/5
* Fi 2821 payer spec tests by @rpassas in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/7
* migrate to new validator by @karlnaden in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/6
* fix validator URL for spec tests by @rpassas in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/10
* Dependency Updates 2024-07-03 by @Jammjammjamm in https://github.com/inferno-framework/davinci-dtr-test-kit/pull/8


# v0.9.0

* Initial public release.
