# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/fail'
require_relative '../../lib/mini_kraken/atomic/k_symbol'


# Load the class under test
require_relative '../../lib/mini_kraken/core/goal'

module MiniKraken
  module Core
    class DummyRelation < Relation
      def initialize
        super('dummy', 2)
      end

      def solver_for(_actuals, ctx)
        DuckFiber.new(-> { ctx.succeeded! })
      end
    end

    describe Goal do
      let(:nullary_relation) { Fail.instance }
      let(:binary_relation) { DummyRelation.new }
      let(:ctx) { Context.new }
      let(:actuals) { [Atomic::KSymbol.new(:pea), Atomic::KSymbol.new(:pod)] }
      subject { Goal.new(binary_relation, actuals) }

      context 'Initialization:' do
        it 'should accept one nullary relation and empty argument array' do
          expect { Goal.new(nullary_relation, []) }.not_to raise_error
        end

        it 'should accept one binary relation and 2-elements array' do
          expect { Goal.new(binary_relation, [Term.new, Term.new]) }.not_to raise_error
        end

        it 'should know its relation' do
          expect(subject.relation).to eq(binary_relation)
        end

        it 'should know its actual arguments' do
          expectations = [Atomic::KSymbol.new(:pea), Atomic::KSymbol.new(:pod)]
          expect(subject.actuals).to eq(expectations)
        end
      end # context

      context 'Provided services:' do
        it 'should fail if relation does not succeed' do
          instance = Goal.new(nullary_relation, [])
          solver = instance.achieve(ctx)
          expect(solver.resume).not_to be_success

          # No more solution...
          expect(solver.resume).to be_nil
        end

        it 'should succeed if relation succeeds' do
          instance = Goal.new(binary_relation, actuals)

          solver = instance.achieve(ctx)
          expect(solver.resume).to be_success

          # No more solution...
          expect(solver.resume).to be_nil
        end
      end # context
    end # describe
  end # module
end # module
