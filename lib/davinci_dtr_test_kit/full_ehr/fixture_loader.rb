require 'singleton'
require 'fhir_models'

module DaVinciDTRTestKit
  class FixtureLoader
    include Singleton

    def initialize
      @cache = {}
    end

    def [](path)
      return unless path.present?

      return @cache[path] if @cache.key?(path)

      fixture_path = File.join(__dir__, 'fixtures', path)
      begin
        fhir_instance = FHIR.from_contents(File.read(fixture_path))
      rescue Errno::ENOENT
        raise Inferno::Exceptions::TestSuiteImplementationException.new('FixtureLoader',
                                                                        "File not found: #{fixture_path}")
      rescue JSON::ParserError => e
        raise Inferno::Exceptions::TestSuiteImplementationException.new('FixtureLoader',
                                                                        "Invalid JSON in #{fixture_path}: #{e.message}")
      end
      if fhir_instance.nil?
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'FixtureLoader',
          "#{fixture_path} does not contain a valid FHIR resource."
        )
      end

      @cache[path] = fhir_instance
    end
  end
end
