# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/syntax/symbol_seq'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe SymbolSeq do
      # Default instantiation rule
      subject(:symbol_sequence) { described_class.new([verb, np, pp]) }

      let(:verb) { NonTerminal.new('Verb') }
      let(:np) { NonTerminal.new('NP') }
      let(:pp) { NonTerminal.new('PP') }

      context 'Initialization:' do
        it 'is created with a list of symbols' do
          # Case of non-empty sequence
          expect { described_class.new([verb, np, pp]) }.not_to raise_error

          # Case of empty sequence
          expect { described_class.new([]) }.not_to raise_error
        end

        it 'knows its members' do
          expect(symbol_sequence.members).to eq([verb, np, pp])
        end

        it 'knows whether it is empty' do
          expect(symbol_sequence).not_to be_empty
          instance = described_class.new([])
          expect(instance).to be_empty
        end

        it 'knows the count of its members' do
          expect(symbol_sequence.size).to be(3)
        end
      end # context

      context 'Provided services:' do
        it 'compares with itself' do
          me = symbol_sequence # Use another name to please Rubocop
          expect(symbol_sequence == me).to be(true)
        end

        it 'compares with another instance' do
          empty_one = described_class.new([])
          expect(symbol_sequence == empty_one).not_to be(true)

          equal_one = described_class.new([verb, np, pp])
          expect(symbol_sequence == equal_one).to be(true)

          unequal_one = described_class.new([verb, pp, np])
          expect(symbol_sequence == unequal_one).not_to be(true)
        end

        it 'complains when unable to compare' do
          err = StandardError
          msg = 'Cannot compare a SymbolSeq with a String'
          expect { symbol_sequence == 'dummy-text' }.to raise_error(err, msg)
        end

        it 'provides human-readable representation of itself' do
          suffix = /::SymbolSeq:\d+ @members=\["Verb", "NP", "PP"\]>$/
          expect(symbol_sequence.inspect).to match(suffix)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
