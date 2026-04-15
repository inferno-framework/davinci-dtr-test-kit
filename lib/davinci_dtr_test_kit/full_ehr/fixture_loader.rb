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

      fhir_instance = FHIR.from_contents(File.read(File.join(__dir__, 'fixtures', path)))
      @cache[path] = fhir_instance
    end
  end
end
