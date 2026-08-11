# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/value_set_expand_support/value_set_expansion_validation'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ValueSetExpansionValidation do # rubocop:disable RSpec/SpecFilePathFormat
  let(:validator) do
    validation_module = described_class
    Class.new { include validation_module }.new
  end
  let(:today) { Date.current }

  def expansion_code(code:, inactive: nil, contains: [])
    FHIR::ValueSet::Expansion::Contains.new(
      system: 'http://example.com/system', code:, inactive:, contains:
    )
  end

  def value_set(timestamp: today.iso8601, contains: [])
    FHIR::ValueSet.new(
      status: 'active',
      expansion: FHIR::ValueSet::Expansion.new(timestamp:, contains:)
    )
  end

  it 'accepts an expansion timestamped today with only active codes' do
    expansion = value_set(contains: [expansion_code(code: 'active')])

    expect(validator.value_set_expansion_errors(expansion, current_date: today)).to be_empty
  end

  it 'rejects an expansion timestamp that is not today' do
    expansion = value_set(timestamp: (today - 1).iso8601)

    expect(validator.value_set_expansion_errors(expansion, current_date: today))
      .to include("expansion.timestamp `#{today - 1}` is not the current date `#{today}`")
  end

  it 'rejects inactive codes at any level of the expansion hierarchy' do
    expansion = value_set(
      contains: [expansion_code(code: 'parent', contains: [expansion_code(code: 'inactive-child', inactive: true)])]
    )

    expect(validator.inactive_expansion_codes(expansion).map(&:code)).to eq(['inactive-child'])
    expect(validator.value_set_expansion_errors(expansion, current_date: today))
      .to include('expansion contains inactive code `http://example.com/system|inactive-child`')
  end

  it 'identifies an inactive display-only expansion entry by its display' do
    expansion = value_set(
      contains: [FHIR::ValueSet::Expansion::Contains.new(display: 'Inactive', inactive: true)]
    )

    expect(validator.value_set_expansion_errors(expansion, current_date: today))
      .to include('expansion contains inactive code `Inactive`')
  end
end
