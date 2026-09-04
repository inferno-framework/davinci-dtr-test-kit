module DaVinciDTRTestKit
  class Generator
    class IGMetadata
      attr_accessor :ig_version, :profiles

      def to_hash
        {
          ig_version:,
          profiles: profiles.map(&:to_hash)
        }
      end

      # Directory/file-safe identifier for a profile. DTR profile ids are already
      # unique per resource type (eg dtr-questionnaireresponse vs
      # dtr-questionnaireresponse-adapt), so the profile url's own id segment is sufficient.
      def snake_case_for_profile(profile_metadata)
        profile_metadata.profile_url.split('StructureDefinition/').last.underscore
      end
    end
  end
end
