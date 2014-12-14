require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/non_terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalNode do
      let(:sample_symbol) { double('fake-symbol') }
      let(:sample_range) { double('fake-range') }
      
      subject { NonTerminalNode.new(sample_symbol, sample_range) }

      context 'Initialization:' do
        it "shouldn't have children yet" do
          expect(subject.children).to be_empty
        end
      end # context
      
      context 'Provided services:' do
        it 'should accept children' do
          child1 = double('first_child')
          child2 = double('second_child')
          child3 = double('third_child')
          expect { subject.add_child(child1) }.not_to raise_error
          subject.add_child(child2)
          subject.add_child(child3)
          expect(subject.children).to eq([child1, child2, child3])
        end
      end # context
    end # describe
  end # module
end # module

# End of file
