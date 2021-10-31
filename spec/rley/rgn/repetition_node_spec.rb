# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/rgn/symbol_node'

# Load the class under test
require_relative '../../../lib/rley/rgn/repetition_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module RGN # Open this namespace to avoid module qualifier prefixes
    describe RepetitionNode do
      let(:a_name) { 'arguments' }
      let(:a_pos) { Lexical::Position.new(3, 4) }
      let(:a_child) { SymbolNode.new(a_pos, a_name) }
      let(:star) { :zero_or_more }

      # Default instantiation rule
      subject { RepetitionNode.new(a_child, star) }

      context 'Initialization:' do
        it 'should be created with a child node and a symbol' do
          expect { RepetitionNode.new(a_child, star) }.not_to raise_error
        end

        it 'should know its child' do
          expect(subject.subnodes.size).to eq(1)
          expect(subject.subnodes.first).to eq(a_child)
          expect(subject.child).to eq(a_child)
        end

        it 'should know its repetition' do
          expect(subject.repetition).to eq(star)
        end
      end # context

      context 'Provided services:' do
        it 'should know its name' do
          # Case repetition == :zero_or_one
          instance = RepetitionNode.new(a_child, :zero_or_one)
          expect(instance.name).to eq('rep_arguments_qmark')

          # Case repetition == :zero_or_more
          expect(subject.name).to eq('rep_arguments_star')

          # Case repetition == :one_or_more
          instance = RepetitionNode.new(a_child, :one_or_more)
          expect(instance.name).to eq('rep_arguments_plus')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
