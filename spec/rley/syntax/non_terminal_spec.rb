# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/non_terminal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe NonTerminal do
      let(:sample_name) { 'noun' }
      subject { NonTerminal.new(sample_name) }

      context 'Initialization:' do
        it 'should be created with a name' do
          expect { NonTerminal.new('noun') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq(sample_name)
        end
        
        it 'should know that is a not a terminal' do
          expect(subject).not_to be_terminal
        end
      end # context

        
      context 'Provided services:' do    
        it 'should know whether it is nullable' do
          expect(subject.nullable?).to be_nil
          subject.nullable = true
          expect(subject).to be_nullable
          subject.nullable = false
          expect(subject).not_to be_nullable          
        end
        
        it 'should know whether it is defined' do
          expect(subject.undefined?).to be_nil
          subject.undefined = true
          expect(subject).to be_undefined
          subject.undefined = false
          expect(subject).not_to be_undefined          
        end

        it 'should know whether it is generative' do
          expect(subject.generative?).to be_nil
          subject.generative = true
          expect(subject).to be_generative
          subject.generative = false
          expect(subject).not_to be_generative          
        end        
      end # context
    end # describe
  end # module
end # module

# End of file
