# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe TerminalNode do
      let(:sample_symbol) { OpenStruct.new(name: 'Noun') }
      let(:sample_token) do
        OpenStruct.new(lexeme: 'world', terminal: sample_symbol)
      end
      let(:sample_range) { double('fake-range') }

      subject { TerminalNode.new(sample_token, sample_range) }

      context 'Initialization:' do
        it 'should be bound to a token' do
          expect(subject.token).to eq(sample_token)
        end
      end # context

      context 'Provided services:' do
        it 'should provide a text representation of itself' do
          expected_text = "Noun[?, ?]: 'world'"
          expect(subject.to_string(0)).to eq(expected_text)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
