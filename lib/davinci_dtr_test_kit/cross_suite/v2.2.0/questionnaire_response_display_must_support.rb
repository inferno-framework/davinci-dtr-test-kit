require 'inferno/ext/fhir_models'
require 'inferno/dsl/profile_metadata'

module DaVinciDTRTestKit
  # Narrows generated DTR QuestionnaireResponse profile metadata to the elements that DTR requires
  # form fillers to be able to display
  # ([conf-5](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-5)):
  # the referenced Questionnaire and its display title, when and by whom the response was authored,
  # each item's text, and answers of every data type, at any depth of item nesting.
  #
  # The rest of the profile's must support set is not required by conf-5 to be populated, so it is
  # left to tester attestation rather than asserted mechanically. `source` is in the conf-5 list
  # but is not must support in the profile, so it never reaches the generated metadata and is
  # likewise covered by attestation only.
  module QuestionnaireResponseDisplayMustSupport
    ELEMENT_PATHS = ['questionnaire', 'authored', 'author', 'item.text'].freeze
    ANSWER_VALUE_PATH = 'item.answer.value[x]'.freeze
    EXTENSION_IDS = ['QuestionnaireResponse.questionnaire.extension:questionnaireDisplay'].freeze

    # Every choice type QuestionnaireResponse.item.answer.value[x] allows (boolean, decimal, integer,
    # date, dateTime, time, string, uri, Attachment, Coding, Quantity, Reference). The DTR profile
    # inherits this list from the base resource unchanged and conf-5 requires all of them, so the
    # single value[x] entry is expanded into one element per type -- the same shape Inferno's
    # metadata extractor produces when a profile flags each type as must support itself.
    ANSWER_VALUE_TYPES = FHIR::QuestionnaireResponse::Item::Answer::MULTIPLE_TYPES['value'].freeze

    # @param generated_metadata [Inferno::DSL::ProfileMetadata] full metadata generated from the profile
    # @return [Inferno::DSL::ProfileMetadata] metadata holding only the conf-5 subset
    def self.metadata_for(generated_metadata)
      must_supports = generated_metadata.must_supports

      Inferno::DSL::ProfileMetadata.new(
        resource: generated_metadata.resource,
        profile_url: generated_metadata.profile_url,
        profile_name: generated_metadata.profile_name,
        profile_version: generated_metadata.profile_version,
        must_supports: {
          elements: display_elements(Array.wrap(must_supports[:elements])),
          extensions: Array.wrap(must_supports[:extensions]).select { |ext| EXTENSION_IDS.include?(ext[:id]) },
          slices: [],
          recursive_elements: Array.wrap(must_supports[:recursive_elements])
        }
      )
    end

    def self.display_elements(elements)
      elements.flat_map do |element|
        if element[:path] == ANSWER_VALUE_PATH
          answer_value_elements(element)
        elsif ELEMENT_PATHS.include?(element[:path])
          [element]
        else
          []
        end
      end
    end

    def self.answer_value_elements(value_element)
      ANSWER_VALUE_TYPES.map do |type|
        {
          path: "#{value_element[:path].delete_suffix('[x]')}#{type.upcase_first}",
          original_path: value_element[:path]
        }
      end
    end

    private_class_method :display_elements, :answer_value_elements
  end
end
