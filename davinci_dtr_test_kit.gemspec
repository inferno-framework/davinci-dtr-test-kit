require_relative 'lib/davinci_dtr_test_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'davinci_dtr_test_kit'
  spec.version       = DaVinciDTRTestKit::VERSION
  spec.authors       = ['Karl Naden', 'Tom Strassner', 'Robert Passas']
  spec.email         = ['inferno@groups.mitre.org']
  spec.summary       = 'Da Vinci DTR Test Kit'
  spec.description   = 'Test Kit for the Da Vinci Documentation Templates and Rules (DTR) FHIR Implementation Guide'
  spec.homepage      = 'https://github.com/inferno-framework/davinci-dtr-test-kit'
  spec.license       = 'Apache-2.0'
  spec.add_runtime_dependency 'inferno_core', '~> 0.4.37'
  spec.add_runtime_dependency 'jwt', '~> 2.6'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.2')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.files = [
    Dir['lib/**/*.rb'],
    Dir['lib/**/*.json'],
    Dir['lib/**/*.md'],
    'LICENSE'
  ].flatten

  spec.require_paths = ['lib']
end
