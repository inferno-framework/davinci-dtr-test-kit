module DaVinciDTRTestKit
  module CanonicalMatching
    # True when the resource's url matches the canonical and, if the canonical includes a
    # version (`url|version`), its version matches too.
    def canonical_matches?(resource, canonical)
      url, version = canonical.split('|', 2)
      resource.try(:url) == url && (version.blank? || resource.version == version)
    end
  end
end
