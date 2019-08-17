# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../support/grammar_abc_helper'

# Load the module under test
require_relative '../../../lib/rley/base/grm_items_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Base # Open this namespace to avoid module qualifier prefixes
    describe 'Testing GrmItemsBuilder' do
      include GrmItemsBuilder # Use mix-in to test
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      context 'Builder pattern behaviour' do
        it 'should create dotted items for a grammar' do
          # Next line calls method from mixin module under test
          items = build_dotted_items(grammar_abc)
          expect(items.size).to eq(8)
          expectations = [
            'S => . A',
            'S => A .',
            'A => . a A c',
            'A => a . A c',
            'A => a A . c',
            'A => a A c .',
            'A => . b',
            'A => b .'
          ]
          expect(items.map(&:to_s)).to eq(expectations)
        end
      end
    end # describe
  end # module
end # module

# End of file
