require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/item_vertex'
require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/lexical/token_range'
require_relative '../../../lib/rley/base/dotted_item'

# Load the class under test
require_relative '../../../lib/rley/sppf/alternative_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module SPPF # Open this namespace to avoid module qualifier prefixes
    describe AlternativeNode do
      # Factory method. Generate a range from its boundary values.
      def range(low, high)
        return Lexical::TokenRange.new(low: low, high: high)
      end
      
      let(:t_a) { Syntax::Terminal.new('A') }
      let(:t_b) { Syntax::Terminal.new('B') }
      let(:t_c) { Syntax::Terminal.new('C') }
      let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }
      let(:sample_prod) do
        Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
      end
      let(:sample_item) { Base::DottedItem.new(sample_prod, 3) }
      let(:sample_vertex) { GFG::ItemVertex.new(sample_item) }
      let(:sample_range) { range(0, 3) }      

      subject { AlternativeNode.new(sample_vertex, sample_range) }

      context 'Construction:' do
        it 'should be created with a item vertex and a token range' do
          expect { AlternativeNode.new(sample_vertex, sample_range) }
            .not_to raise_error
        end      
      end
      
      context 'Initialization:' do
        it 'should know its token range' do
          expect(subject.range).to eq(sample_range)
          expect(subject.origin).to eq(sample_range.low)
        end

        it "shouldn't have children yet" do
          expect(subject.subnodes).to be_empty
        end
      end # context
      
      context 'Provided services:' do
        it 'should accept the addition of subnodes' do
          subnode1 = double('first_subnode')
          subnode2 = double('second_subnode')
          subnode3 = double('third_subnode')
          expect { subject.add_subnode(subnode1) }.not_to raise_error
          subject.add_subnode(subnode2)
          subject.add_subnode(subnode3)
          expect(subject.subnodes).to eq([subnode3, subnode2, subnode1])
        end


        it 'should have a string representation' do    
          expect(subject.to_string(0)).to eq('Alt(sentence => A B C .)[0, 3]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
