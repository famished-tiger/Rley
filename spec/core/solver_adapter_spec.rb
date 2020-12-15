# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require 'singleton'

require_relative '../../lib/mini_kraken/core/context'

# Load the class under test
require_relative '../../lib/mini_kraken/core/solver_adapter'


module MiniKraken
  module Core
    describe SolverAdapter do
      let(:ctx) { Context.new }
      let(:fib) { make_fiber(ctx, true, true, false, nil) }
      let(:blk) do
        lambda do |adapter, _context|
          adapter.adaptee.resume
        end
      end
      subject { SolverAdapter.new(fib, &blk) }

      # Factory method.
      def make_fiber(ctx, *args)
        Fiber.new do
          signature = *args
          signature.each do |outcome|
            if outcome
              Fiber.yield ctx.succeeded!
              next
            elsif outcome.nil?
              Fiber.yield nil
              break
            else
              Fiber.yield ctx.failed!
              next
            end
          end
        end
      end

      context 'Initialization:' do
        it 'should be initialized with a Fiber-like object' do
          expect { SolverAdapter.new(fib, &blk) }.not_to raise_error
        end

        it 'should know its adaptee' do
          expect(subject.adaptee).to eq(fib)
        end
      end # context

      context 'Provided services:' do
        it 'should respond to the resume message' do
          result = subject.resume(ctx)
          expect(result).to be_success

          result = subject.resume(ctx)
          expect(result).to be_success

          result = subject.resume(ctx)
          expect(result).to be_failure

          result = subject.resume(ctx)
          expect(result).to be_nil
        end
      end # context
    end # describe
  end # module
end # module
