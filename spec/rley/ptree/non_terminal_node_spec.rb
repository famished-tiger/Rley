# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/ptree/terminal_node'
# Load the class under test
require_relative '../../../lib/rley/ptree/non_terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalNode do
      # Factory method. Generate a range from its boundary values.
      def range(low, high)
        return Lexical::TokenRange.new(low: low, high: high)
      end

      subject(:a_node) { described_class.new(sample_symbol, sample_range) }

      let(:sample_symbol) do
        OpenStruct.new(name: 'VP')
      end
      let(:sample_range) { range(0, 3) }

      context 'Initialization:' do
        it "doesn't have subnodes yet" do
          expect(a_node.subnodes).to be_empty
        end
      end # context

      context 'Provided services:' do
        def build_token(aLexeme, aSymbolName)
          terminal = OpenStruct.new(name: aSymbolName)
          return OpenStruct.new(lexeme: aLexeme, terminal: terminal)
        end

        it 'accepts the addition of subnodes' do
          child1 = double('first_child')
          child2 = double('second_child')
          child3 = double('third_child')
          expect { a_node.add_subnode(child1) }.not_to raise_error
          a_node.add_subnode(child2)
          a_node.add_subnode(child3)
          expect(a_node.subnodes).to eq([child3, child2, child1])
        end

        # rubocop: disable Naming/VariableNumber
        it 'provides a text representation of itself' do
          # Case 1: no child
          expected_text = 'VP[0, 3]'
          expect(a_node.to_string(0)).to eq(expected_text)

          # Case 2: with subnodes
          verb = build_token('catch', 'Verb')
          child_1_1 = TerminalNode.new(verb, range(0, 1))
          np = OpenStruct.new(name: 'NP')
          child_1_2 = described_class.new(np, range(1, 3))
          det = build_token('that', 'Determiner')
          child_2_1 = TerminalNode.new(det, range(1, 2))
          nominal = OpenStruct.new(name: 'Nominal')
          child_2_2 = described_class.new(nominal, range(2, 3))
          noun = build_token('bus', 'Noun')
          child_3_1 = TerminalNode.new(noun, range(2, 3))
          # We reverse the sequence of subnode addition
          a_node.add_subnode(child_1_2)
          a_node.add_subnode(child_1_1)
          child_1_2.add_subnode(child_2_2)
          child_1_2.add_subnode(child_2_1)
          child_2_2.add_subnode(child_3_1)
          expected_text = <<-SNIPPET
VP[0, 3]
+- Verb[0, 1]: 'catch'
+- NP[1, 3]
   +- Determiner[1, 2]: 'that'
   +- Nominal[2, 3]
      +- Noun[2, 3]: 'bus'
SNIPPET
          expect(a_node.to_string(0)).to eq(expected_text.chomp)
        end
        # rubocop: enable Naming/VariableNumber
      end # context
    end # describe
  end # module
end # module

# End of file
