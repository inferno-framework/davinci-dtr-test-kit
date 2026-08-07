require 'active_support/all'
require 'inferno/ext/fhir_models'
require 'inferno/entities/entity'
require 'inferno/entities/attributes'
require 'inferno/entities/ig'

require_relative 'generator/ig_metadata'
require_relative 'generator/profile_metadata_extractor'

module DaVinciDTRTestKit
  # Generates profile metadata files (used by the test kit's must support tests)
  # from a DTR IG package into cross_suite/generated/<ig_version>.
  class Generator
    TARGET_IG_VERSIONS = ['2.2.0'].freeze

    # Must support checks currently only for Questionnaires
    # and scoped to only differential for standard and adaptive
    TARGET_PROFILES_AND_ELEMENT_SCOPE = {
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-base-questionnaire' => 'snapshot',
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt' => 'differential',
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire' => 'differential'
    }.freeze

    def self.generate
      ig_packages = Dir.glob(File.join(Dir.pwd, 'lib', 'davinci_dtr_test_kit', 'igs', '*.tgz'))

      ig_packages.each do |ig_package|
        generator = new(ig_package)
        next unless TARGET_IG_VERSIONS.include?(generator.ig_version_from_file_name)

        generator.generate
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name

    def initialize(ig_file_name)
      self.ig_file_name = ig_file_name
    end

    def ig_version_from_file_name
      File.basename(ig_file_name, '.tgz').split('_').last
    end

    def generate
      puts "Generating profile metadata for IG #{File.basename(ig_file_name)}"
      load_ig_package
      extract_metadata
      write_profile_metadata
    end

    def load_ig_package
      self.ig_resources = Inferno::Entities::IG.from_file(
        ig_file_name,
        standalone_resources_directory: ig_file_name.chomp('.tgz')
      )
    end

    # DTR profiles analyzed include the Questionnaires
    def target_profiles
      ig_resources.resources_by_type['StructureDefinition'].select do |structure_definition|
        TARGET_PROFILES_AND_ELEMENT_SCOPE.key?(structure_definition.url)
      end
    end

    def extract_metadata
      self.ig_metadata = IGMetadata.new
      ig_metadata.ig_version = "v#{ig_resources.ig_resource.version}"
      ig_metadata.profiles = target_profiles.map do |profile|
        ProfileMetadataExtractor.new(profile.url, ig_resources,
                                     TARGET_PROFILES_AND_ELEMENT_SCOPE[profile.url]).profile_metadata
      end

      FileUtils.mkdir_p(base_output_dir)
      File.write(File.join(base_output_dir, 'metadata.yml'), YAML.dump(ig_metadata.to_hash))
    end

    def base_output_dir
      File.join(__dir__, 'cross_suite', 'generated', ig_metadata.ig_version)
    end

    def write_profile_metadata
      ig_metadata.profiles.each do |profile_metadata|
        metadata_file_dir = File.join(base_output_dir, ig_metadata.snake_case_for_profile(profile_metadata))
        FileUtils.mkdir_p(metadata_file_dir)
        File.write(File.join(metadata_file_dir, 'metadata.yml'), YAML.dump(profile_metadata.to_hash))
      end
    end
  end
end
