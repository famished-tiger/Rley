require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/syntax/symbol_seq'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe SymbolSeq do
      let(:verb) { NonTerminal.new('Verb') }
      let(:np) { NonTerminal.new('NP') }
      let(:pp) { NonTerminal.new('PP') }

      # Default instantiation rule
      subject { SymbolSeq.new([verb, np, pp]) }

      context 'Initialization:' do
        it 'should be created with a list of symbols' do
          # Case of non-empty sequence
          expect { SymbolSeq.new([verb, np, pp]) }.not_to raise_error

          # Case of empty sequence
          expect { SymbolSeq.new([]) }.not_to raise_error
        end

        it 'should know its members' do
          expect(subject.members).to eq([verb, np, pp])
        end

        it 'should know whether it is empty' do
          expect(subject).not_to be_empty
          instance = SymbolSeq.new([])
          expect(instance).to be_empty
        end

        it 'should the count of its members' do
          expect(subject.size).to eq(3)
        end
      end # context

      context 'Provided services:' do
        it 'should compare compare with itself' do
          me = subject # Use another name to please Rubocop
          expect(subject == me).to eq(true)
        end

        it 'should compare with another instance' do
          empty_one = SymbolSeq.new([])
          expect(subject == empty_one).not_to eq(true)

          equal_one = SymbolSeq.new([verb, np, pp])
          expect(subject == equal_one).to eq(true)

          unequal_one = SymbolSeq.new([verb, pp, np])
          expect(subject == unequal_one).not_to eq(true)
        end
        
        it 'should complain when unable to compare' do
          err = StandardError
          msg = 'Cannot compare a SymbolSeq with a String'
          expect { subject == 'dummy-text' }.to raise_error(err, msg)
        end
        
        it 'should provide human-readable representation of itself' do
          suffix = /::SymbolSeq:\d+ @members=\["Verb", "NP", "PP"\]>$/
          expect(subject.inspect).to match(suffix)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
