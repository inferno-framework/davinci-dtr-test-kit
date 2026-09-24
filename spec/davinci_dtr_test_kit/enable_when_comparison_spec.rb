require 'davinci_dtr_test_kit/cross_suite/v2.2.0/enable_when_comparison'

RSpec.describe DaVinciDTRTestKit::EnableWhenComparison do
  # Dates and times are compared as moments, so an offset, a trailing fractional second or a shorter
  # precision does not decide the answer.
  describe 'dates and times' do
    it 'treats the same instant written with different offsets as equal' do
      expect(described_class.met?('=', '2026-01-01T10:00:00-05:00', '2026-01-01T15:00:00Z')).to be(true)
    end

    it 'ignores a trailing fractional second' do
      expect(described_class.met?('=', '2026-01-01T10:00:00Z', '2026-01-01T10:00:00.000Z')).to be(true)
    end

    it 'orders by the instant rather than by the text' do
      # The first names a later local date but an earlier instant
      expect(described_class.met?('<', '2026-03-01T00:00:00+01:00', '2026-02-28T23:30:00Z')).to be(true)
      expect(described_class.met?('>', '2026-03-01T00:00:00+01:00', '2026-02-28T23:30:00Z')).to be(false)
    end

    it 'compares plain dates' do
      expect(described_class.met?('<', '2026-01-01', '2026-06-01')).to be(true)
      expect(described_class.met?('=', '2026-01-01', '2026-01-01')).to be(true)
    end

    it 'reads a date that stops short of a full timestamp as its first moment' do
      expect(described_class.met?('=', '2026', '2026-01-01')).to be(true)
      expect(described_class.met?('=', '2026-01', '2026-01-01T00:00:00Z')).to be(true)
    end

    it 'compares times, including a trailing fractional second' do
      expect(described_class.met?('=', '10:00:00', '10:00:00.000')).to be(true)
      expect(described_class.met?('<', '09:30:00', '10:00:00')).to be(true)
    end

    it 'does not compare a time of day against a date' do
      expect(described_class.met?('=', '10:00:00', '2026-01-01')).to be(false)
      expect(described_class.met?('<', '10:00:00', '2026-01-01')).to be(false)
    end
  end

  describe 'values that are not temporal' do
    it 'still compares strings exactly' do
      expect(described_class.met?('=', 'yes', 'yes')).to be(true)
      expect(described_class.met?('=', 'yes', 'no')).to be(false)
    end

    it 'still compares numbers' do
      expect(described_class.met?('>', 5, 3)).to be(true)
      expect(described_class.met?('<=', 3, 3)).to be(true)
    end
  end
end
