require 'inferno/dsl/must_support_metadata_extractor'
require 'inferno/dsl/profile_metadata'

module DaVinciDTRTestKit
  class Generator
    class ProfileMetadataExtractor
      attr_accessor :profile_url, :ig_resources, :element_scope

      def initialize(profile_url, ig_resources, element_scope = 'snapshot')
        self.profile_url = profile_url
        self.ig_resources = ig_resources
        self.element_scope = element_scope
      end

      def profile_metadata
        @profile_metadata ||=
          Inferno::DSL::ProfileMetadata.new(
            resource:,
            profile_url:,
            profile_name:,
            profile_version:,
            must_supports:
          )
      end

      def profile
        @profile ||= ig_resources.profile_by_url(profile_url)
      end

      def profile_elements
        @profile_elements ||= element_scope == 'snapshot' ? profile.snapshot.element : profile.differential.element
      end

      def resource
        profile.type
      end

      def profile_name
        profile.title.gsub('  ', ' ')
      end

      def profile_version
        profile.version
      end

      def must_support_metadata_extractor
        @must_support_metadata_extractor ||=
          Inferno::DSL::MustSupportMetadataExtractor.new(profile_elements, profile, resource, ig_resources)
      end

      def must_supports
        @must_supports ||=
          must_support_metadata_extractor.must_supports
      end
    end
  end
end
