# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe TerminalNode do
      subject(:a_node) { described_class.new(sample_token, sample_range) }

      let(:sample_symbol) { OpenStruct.new(name: 'Noun') }
      let(:sample_token) do
        OpenStruct.new(lexeme: 'world', terminal: sample_symbol)
      end
      let(:sample_range) { double('fake-range') }

      context 'Initialization:' do
        it 'is bound to a token' do
          expect(a_node.token).to eq(sample_token)
        end
      end # context

      context 'Provided services:' do
        it 'provides a text representation of itself' do
          expected_text = "Noun[?, ?]: 'world'"
          expect(a_node.to_string(0)).to eq(expected_text)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
