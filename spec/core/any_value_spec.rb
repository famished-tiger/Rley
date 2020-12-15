# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/any_value'


module MiniKraken
  module Core
    describe AnyValue do
      let(:some_rank) { 2 }
      subject { AnyValue.new(some_rank) }

      context 'Initialization:' do
        it "should be initialized with a variable's rank" do
          expect { AnyValue.new(0) }.not_to raise_error
        end

        it 'should know its rank' do
          expect(subject.rank).to eq(some_rank)
        end
      end # context
      
      context 'Provided services:' do
        it 'should compare itself to another instance' do
          expect(subject ==  AnyValue.new(some_rank)).to be_truthy
          expect(subject ==  AnyValue.new(1)).to be_falsey          
        end
        
        it 'should compare itself to an integer' do
          expect(subject == some_rank).to be_truthy  
          expect(subject == 1).to be_falsey
        end
        
        it 'should compare itself to a symbol' do
          expect(subject == :_2).to be_truthy  
          expect(subject == :_1).to be_falsey
        end   

        it 'should know its text representation' do
          expect(subject.to_s).to eq('_2')
        end
        
        it 'should know that it represents a non-pinned variable' do
          ctx = double('dummy-context')
          expect(subject).not_to be_pinned(ctx)
        end
      end
    end # describe
  end # module
end # module
