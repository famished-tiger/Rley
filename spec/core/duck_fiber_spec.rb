# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/duck_fiber'

module MiniKraken
  module Core
    describe DuckFiber do
      Callable = Struct.new(:proc) do
        def call
          proc.call
        end
      end
    
      let(:ctx) { Core::Context.new }
      let(:callable) { -> { ctx.failed! }  }
      subject { DuckFiber.new(callable) }

      context 'Initialization:' do
        it 'could be initialized with a Proc' do
          expect { DuckFiber.new(-> { ctx.failed }) }.not_to raise_error
        end
        
        it "could be initialized with an object that responds to 'call'" do
          expect { DuckFiber.new(callable) }.not_to raise_error
        end        

        it 'should know its callable object' do
          expect(subject.callable).to eq(callable)
        end
      end # context

      context 'Provided services:' do
        it 'should behave like a Fiber yielding the given Context' do
          result = nil
          expect { result = subject.resume }.not_to raise_error
          expect(result).to eq(ctx)
          expect(ctx).to be_failure

          # Only one result should be yielded
          expect(subject.resume).to be_nil
        end
      end # context
    end # describe
  end # module
end # module
