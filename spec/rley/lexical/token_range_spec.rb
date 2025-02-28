# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/lexical/token_range'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Lexical # Open this namespace to avoid module qualifier prefixes
    describe TokenRange do
      let(:sample_range) { { low: 0, high: 5 } }

      # Default instantiation rule
      subject(:a_range) { described_class.new(sample_range) }

      context 'Initialization:' do
        it 'is created with a range Hash' do
          # No bounds provided
          expect { described_class.new({}) }.not_to raise_error

          # Low bound provided
          expect { described_class.new(low: 0) }.not_to raise_error

          # High bound provided
          expect { described_class.new(high: 5) }.not_to raise_error

          # Both bounds provided
          expect { described_class.new(low: 0, high: 5) }.not_to raise_error
        end

        it 'is created with another TokenRange' do
          # Low bound provided
          instance = described_class.new(low: 0)
          expect { described_class.new(instance) }.not_to raise_error

          # High bound provided
          instance = described_class.new(high: 5)
          expect { described_class.new(instance) }.not_to raise_error

          # Both bounds provided
          instance = described_class.new(low: 0, high: 5)
          expect { described_class.new(instance) }.not_to raise_error
        end

        it 'knows its low bound' do
          expect(a_range.low).to eq(0)
        end

        it 'knows its high bound' do
          expect(a_range.high).to eq(5)
        end
      end # context

      context 'Provided services:' do
        it 'compares to another range' do
          me = a_range
          expect(a_range == me).to be(true)
          equal = described_class.new(low: 0, high: 5)
          expect(a_range == equal).to be(true)
          # expect(a_range == [0..5]).to be(true)
          expect(a_range == [0, 5]).to be(true)
        end


        it 'knows whether it is bounded or not' do
          expect(a_range).to be_bounded

          # Case: only low bound is set
          instance = described_class.new(low: 0)
          expect(instance).not_to be_bounded

          # Case: only upper bound is set
          instance = described_class.new(high: 5)
          expect(instance).not_to be_bounded

          # No bound is set
          instance = described_class.new({})
          expect(instance).not_to be_bounded
        end

        it 'assigns its open bounds' do
          some_range = { low: 1, high: 4 }

          ###########
          # Case of bounded token range...
          a_range.assign(some_range)

          # ... should be unchanged
          expect(a_range.low).to eq(sample_range[:low])
          expect(a_range.high).to eq(sample_range[:high])

          ###########
          # Case: only low bound is set
          instance = described_class.new(low: 0)
          instance.assign(some_range)

          # Expectation: high is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(0)
          expect(instance.high).to eq(4)

          ###########
          # Case: only high bound is set
          instance = described_class.new(high: 5)
          instance.assign(some_range)

          # Expectation: low is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(1)
          expect(instance.high).to eq(5)

          ###########
          # Case: no bound is set
          instance = described_class.new({})
          instance.assign(some_range)

          # Expectation: low is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(1)
          expect(instance.high).to eq(4)
        end

        it 'tells whether an index value lies outside the range' do
          # Out of range...
          expect(a_range.out_of_range?(-1)).to be(true)
          expect(a_range.out_of_range?(6)).to be(true)

          # On boundaries...
          expect(a_range.out_of_range?(0)).to be(false)
          expect(a_range.out_of_range?(5)).to be(false)

          # Inside boundaries
          expect(a_range.out_of_range?(2)).to be(false)

          instance = described_class.new(low: nil, high: 5)

          # Lower bound is nil
          expect(instance.out_of_range?(-1)).to be(false)
          expect(instance.out_of_range?(5)).to be(false)
          expect(instance.out_of_range?(6)).to be(true)

          instance = described_class.new(low: 0, high: nil)

          # Upper bound is nil
          expect(instance.out_of_range?(-1)).to be(true)
          expect(instance.out_of_range?(0)).to be(false)
          expect(instance.out_of_range?(6)).to be(false)
        end

        it 'provides a text representation of itself' do
          # Case 1: not bound is set
          instance = described_class.new({})
          expect(instance.to_string(0)).to eq('[?, ?]')

          # Case: only low bound is set
          instance = described_class.new(low: 0)
          expect(instance.to_string(0)).to eq('[0, ?]')

          # Case: only upper bound is set
          instance = described_class.new(high: 5)
          expect(instance.to_string(0)).to eq('[?, 5]')

          # Case: both bounds are set
          instance = described_class.new(low: 0, high: 5)
          expect(instance.to_string(0)).to eq('[0, 5]')
        end
      end
    end # describe
  end # module
end # module

# End of file
