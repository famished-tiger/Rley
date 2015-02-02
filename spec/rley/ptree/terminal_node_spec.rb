require 'ostruct'
require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe TerminalNode do
      let(:sample_symbol) do
        OpenStruct.new(name: 'Noun')
      end
      let(:sample_range) { double('fake-range') }
      
      subject { TerminalNode.new(sample_symbol, sample_range) }
      
      context 'Initialization:' do
        it "shouldn't be already bound to a token" do
          expect(subject.token).to be_nil
        end
      end # context
      
      context 'Provided services:' do
        it 'should provide a text representation of itself' do
          # Case 1: not bound to a token
          expected_text = "Noun[?, ?]: '(nil)'"
          expect(subject.to_string(0)).to eq(expected_text)
          
          # Case 2: bound to token
          subject.token = OpenStruct.new(lexeme: 'peace')
          expected_text = "Noun[?, ?]: 'peace'"
          expect(subject.to_string(0)).to eq(expected_text)          
        end
      end # context
    end # describe
  end # module
end # module

# End of file
