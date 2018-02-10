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
      let(:sample_symbol) { Syntax::Terminal.new('Noun') }
      let(:sample_token) { Lexical::Token.new('language', sample_symbol) }
      let(:sample_position) { 3 } 

      subject { TokenNode.new(sample_token, sample_position) }

      context 'Initialization:' do
        it 'should know its token' do
          expect(subject.token).to eq(sample_token)
        end

        it 'should know its token range' do
          expect(subject.origin).to eq(sample_position)
          expect(subject.range.low).to eq(sample_position)
          expect(subject.range.high).to eq(sample_position + 1)
        end
      end # context
      
      context 'Provided services:' do
        it 'should know its string representation' do
          expect(subject.to_string(0)).to eq('Noun[3, 4]')
          expect(subject.inspect).to eq('Noun[3, 4]')
        end
        
        it 'should return a key value of itself' do
          expect(subject.key).to eq('Noun[3, 4]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
