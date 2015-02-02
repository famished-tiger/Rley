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
        return TokenRange.new(low: low, high: high)
      end
    
      let(:sample_symbol) do
        OpenStruct.new(name: 'VP')
      end
      let(:sample_range) { range(0, 3) }
      
      subject { NonTerminalNode.new(sample_symbol, sample_range) }

      context 'Initialization:' do
        it "shouldn't have children yet" do
          expect(subject.children).to be_empty
        end
      end # context
      
      context 'Provided services:' do
        it 'should accept the addition of children' do
          child1 = double('first_child')
          child2 = double('second_child')
          child3 = double('third_child')
          expect { subject.add_child(child1) }.not_to raise_error
          subject.add_child(child2)
          subject.add_child(child3)
          expect(subject.children).to eq([child1, child2, child3])
        end
        
        it 'should provide a text representation of itself' do
          # Case 1: no child
          expected_text = "VP[0, 3]"
          expect(subject.to_string(0)).to eq(expected_text)
          
          # Case 2: with children
          child_1_1 = TerminalNode.new(OpenStruct.new(name: 'Verb'), range(0, 1))
          child_1_2 = NonTerminalNode.new(OpenStruct.new(name: 'NP'), range(1, 3))
          child_2_1 = TerminalNode.new(OpenStruct.new(name: 'Determiner'), range(1, 2))
          child_2_2 = NonTerminalNode.new(OpenStruct.new(name: 'Nominal'), range(2, 3))          
          child_3_1 = TerminalNode.new(OpenStruct.new(name: 'Noun'), range(2, 3))
          subject.add_child(child_1_1)
          subject.add_child(child_1_2)
          child_1_2.add_child(child_2_1)
          child_1_2.add_child(child_2_2)
          child_2_2.add_child(child_3_1)
          child_1_1.token = OpenStruct.new(lexeme: 'catch')
          child_2_1.token = OpenStruct.new(lexeme: 'that')
          child_3_1.token = OpenStruct.new(lexeme: 'bus')
          expected_text = <<-SNIPPET
VP[0, 3]
+- Verb[0, 1]: 'catch'
+- NP[1, 3]
   +- Determiner[1, 2]: 'that'
   +- Nominal[2, 3]
      +- Noun[2, 3]: 'bus'
SNIPPET
          expect(subject.to_string(0)).to eq(expected_text.chomp)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
