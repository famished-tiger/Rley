# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/symbol_seq'

# Load the class under test
require_relative '../../../lib/rley/syntax/production'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe Production do
      # Default instantiation rule
      subject(:a_production) { described_class.new(sentence, sequence) }

      let(:sentence) { NonTerminal.new('Sentence') }
      let(:np) { NonTerminal.new('NP') }
      let(:vp) { NonTerminal.new('VP') }
      let(:sequence) { [np, vp] }

      context 'Initialization:' do
        it 'is created with a non-terminal and a symbol sequence' do
          expect { described_class.new(sentence, sequence) }.not_to raise_error
        end

        it 'complains when its rhs is nil' do
          err = StandardError
          msg_prefix = 'Right side of a production of the kind '
          msg_suffix = "'Sentence' => ... is nil."
          msg = msg_prefix + msg_suffix
          expect { described_class.new(sentence, nil) }.to raise_error(err, msg)
        end

        it 'knows its lhs' do
          expect(a_production.lhs).to eq(sentence)
          expect(a_production.head).to eq(sentence)
        end

        it 'knows its rhs' do
          expect(a_production.rhs).to eq(sequence)
          expect(a_production.body).to eq(sequence)
        end

        it 'is free from constraints at start' do
          expect(a_production.constraints).to be_empty
        end

        it 'knows whether its rhs is empty' do
          expect(a_production).not_to be_empty

          instance = described_class.new(sentence, [])
          expect(instance).to be_empty
        end

        it 'is anonymous at creation' do
          expect(a_production.name).to be_nil
        end

        it 'complains if its lhs is not a non-terminal' do
          err = StandardError
          msg_prefix = 'Left side of production must be a non-terminal symbol'
          msg_suffix = ", found a #{String} instead."
          msg = msg_prefix + msg_suffix
          expect { described_class.new('wrong', sequence) }.to raise_error(err, msg)
        end
      end # context

      context 'Provided services:' do
        it 'accepts a name (i)' do
          a_name = 'nominem'
          a_production.name = a_name
          expect(a_production.name).to eq(a_name)
        end

        it 'accepts a name (ii)' do
          a_name = 'nominem'
          a_production.as(a_name)
          expect(a_production.name).to eq(a_name)
        end

        it 'provides a human-readable representation of itself' do
          a_production.name = 'some name'
          prefix = /^#<Rley::Syntax::Production:\d+ @name="some name"/
          expect(a_production.inspect).to match(prefix)
          pattern = /@lhs=Sentence @rhs=#<Rley::Syntax::SymbolSeq/
          expect(a_production.inspect).to match(pattern)
          suffix = /> @generative=>$/
          expect(a_production.inspect).to match(suffix)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
