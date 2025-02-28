# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/lexical/token_range'
require_relative '../../../lib/rley/lexical/token'

# Load the class under test
require_relative '../../../lib/rley/sppf/token_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module SPPF # Open this namespace to avoid module qualifier prefixes
    describe TokenNode do
      subject(:a_node) { described_class.new(sample_token, sample_rank) }

      let(:sample_symbol) { Syntax::Terminal.new('Noun') }
      let(:sample_position) { Lexical::Position.new(3, 4) }
      let(:sample_token) do
        Lexical::Token.new('language', sample_symbol, sample_position)
      end
      let(:sample_rank) { 3 }

      context 'Initialization:' do
        it 'knows its token' do
          expect(a_node.token).to eq(sample_token)
        end

        it 'knows its token range' do
          expect(a_node.origin).to eq(sample_rank)
          expect(a_node.range.low).to eq(sample_rank)
          expect(a_node.range.high).to eq(sample_rank + 1)
        end
      end # context

      context 'Provided services:' do
        it 'knows its string representation' do
          expect(a_node.to_string(0)).to eq('Noun[3, 4]')
          expect(a_node.inspect).to eq('Noun[3, 4]')
        end

        it 'returns a key value of itself' do
          expect(a_node.key).to eq('Noun[3, 4]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
