require 'inferno/ext/fhir_models'
require 'inferno/dsl/profile_metadata'

module DaVinciDTRTestKit
  # Builds the must support metadata for the client QuestionnaireResponse must support test from the
  # metadata generated for the DTR QuestionnaireResponse profile. Every must support element and
  # extension in the profile is kept, with two additions driven by
  # [conf-5](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-5), which
  # requires form fillers to be able to display answers of all data types and the source's name:
  # - `item.answer.value[x]` is expanded into one element per choice type, so each type must be
  #   observed rather than any one of them.
  # - `source` is added, because the profile does not flag it as must support.
  module QuestionnaireResponseMustSupportMetadata
    ANSWER_VALUE_PATH = 'item.answer.value[x]'.freeze

    # Every choice type QuestionnaireResponse.item.answer.value[x] allows (boolean, decimal, integer,
    # date, dateTime, time, string, uri, Attachment, Coding, Quantity, Reference). The DTR profile
    # inherits this list from the base resource unchanged. The expanded elements use the same shape
    # Inferno's metadata extractor produces when a profile flags each type as must support itself.
    ANSWER_VALUE_TYPES = FHIR::QuestionnaireResponse::Item::Answer::MULTIPLE_TYPES['value'].freeze

    ADDITIONAL_ELEMENTS = [{ path: 'source', types: ['Reference'] }].freeze

    # @param generated_metadata [Inferno::DSL::ProfileMetadata] metadata generated from the profile
    # @return [Inferno::DSL::ProfileMetadata]
    def self.metadata_for(generated_metadata)
      must_supports = generated_metadata.must_supports

      Inferno::DSL::ProfileMetadata.new(
        resource: generated_metadata.resource,
        profile_url: generated_metadata.profile_url,
        profile_name: generated_metadata.profile_name,
        profile_version: generated_metadata.profile_version,
        must_supports: must_supports.merge(elements: elements(Array.wrap(must_supports[:elements])))
      )
    end

    def self.elements(generated_elements)
      expanded = generated_elements.flat_map do |element|
        element[:path] == ANSWER_VALUE_PATH ? answer_value_elements(element) : [element]
      end

      expanded + ADDITIONAL_ELEMENTS.map(&:dup)
    end

    def self.answer_value_elements(value_element)
      ANSWER_VALUE_TYPES.map do |type|
        {
          path: "#{value_element[:path].delete_suffix('[x]')}#{type.upcase_first}",
          original_path: value_element[:path]
        }
      end
    end

    private_class_method :elements, :answer_value_elements
  end
end
