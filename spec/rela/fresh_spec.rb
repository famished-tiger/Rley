# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/all_core'

require_relative '../support/factory_atomic'
require_relative '../support/factory_composite'
require_relative '../../lib/mini_kraken/rela/all_rela'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/fresh'

module MiniKraken
  module Rela
    describe Fresh do
      include MiniKraken::FactoryAtomic # Use mix-in module
      include MiniKraken::FactoryComposite # Use mix-in module
      subject { Fresh.instance }


      def var(aName)
        Core::LogVar.new(aName)
      end

      # Convenience method to factor out repeated statements
      def solve(arg1, arg2)
        solver = subject.solver_for([arg1, arg2], ctx)
        outcome = solver.resume
        outcome
      end

      context 'Initialization:' do
        it 'should know its relation name' do
          expect(subject.name).to eq('fresh')
        end

        it 'should know its arity (binary)' do
          expect(subject.arity).to be_binary
        end

        it 'should be frozen' do
          expect(subject).to be_frozen
        end
      end # context

      context 'Provided services:' do
        let(:ctx) { Core::Context.new }
        let(:bean) { k_symbol(:bean) }
        let(:pea) { k_symbol(:pea) }
        let(:corn) { k_symbol(:corn) }
        let(:meal) { k_symbol(:meal) }
        let(:red) { k_symbol(:red) }
        let(:soup) { k_symbol(:soup) }
        let(:split) { k_symbol(:split) }
        let(:fails) { Core::Goal.new(Core::Fail.instance, []) }
        let(:succeeds) { Core::Goal.new(Core::Succeed.instance, []) }
        let(:var_q) { var('q') }
        let(:ref_q) { Core::LogVarRef.new('q') }
        let(:ref_r) { Core::LogVarRef.new('r') }
        let(:ref_x) { Core::LogVarRef.new('x') }
        let(:ref_y) { Core::LogVarRef.new('y') }

        def unify(term1, term2)
           Core::Goal.new(Unify.instance, [term1, term2])
        end

        def conj2(term1, term2)
           Core::Goal.new(Conj2.instance, [term1, term2])
        end

        def disj2(term1, term2)
           Core::Goal.new(Disj2.instance, [term1, term2])
        end

        before(:each) { ctx.add_vars('q')  }

        it 'should create a solver' do
          subgoal = unify(ref_x, ref_q)
          fresh_goal = Core::Goal.new(subject, [k_string('x'), subgoal])
          solver = subject.solver_for(fresh_goal.actuals, ctx)
          expect(solver.resume(ctx)).to be_success
          current_scope = ctx.symbol_table.current_scope
          expect(current_scope.defns.include? 'x').to be_truthy
          expect(current_scope.parent.defns.include? 'q').to be_truthy
          fusion = ctx.blackboard.move_queue.last
          expect(fusion).to be_kind_of(Core::Fusion)
          expect(solver.resume(ctx)).to be_nil
        end

        it 'should allow the nesting of fresh goals' do
          ref_y = Core::LogVarRef.new('y')
          subsubgoal = unify(ref_y, ref_q)
          fresh_subgoal = Core::Goal.new(subject, [k_string('y'), subsubgoal])
          fresh_goal = Core::Goal.new(subject, [k_string('x'), fresh_subgoal])
          solver = subject.solver_for(fresh_goal.actuals, ctx)
          expect(solver.resume(ctx)).to be_success
          current_scope = ctx.symbol_table.current_scope
          expect(current_scope.defns.include? 'y').to be_truthy
          expect(current_scope.parent.defns.include? 'x').to be_truthy
          expect(current_scope.parent.parent.defns.include? 'q').to be_truthy
          fusion = ctx.blackboard.move_queue.last
          expect(fusion).to be_kind_of(Core::Fusion)
          expect(solver.resume(ctx)).to be_nil
        end

        it 'should create a simple goal' do
          # Covers frame 1:21
          # (run* q (fresh (x) (== 'pea q))) ;; => (pea)
          subgoal = unify(pea, ref_q)
          goal = Fresh.build_goal('x', subgoal)

          expect(goal).to be_kind_of(Core::Goal)
          expect(goal.relation).to be_kind_of(Fresh)
          expect(goal.actuals[0]).to eq('x') # Name of local variable
          expect(goal.actuals[1]).to eq(subgoal)
          solver = subject.solver_for(goal.actuals, ctx)
          expect(solver.resume(ctx)).to be_success
          result = ctx.build_solution
          expect(result['q']).to eq(pea)
        end

        it 'should create a goal with conjuncted sub-goals' do
          # Covers inner part of frame 1:78
          #   (fresh (x y)
          #     (disj2
          #       (conj2 (== 'split x) (== 'pea y))
          #       (conj2 (== 'red x) (== 'bean y)))
          #     (== '(,x ,y soup) r)))

          subgoals = [disj2(
              conj2(unify(split, ref_x), unify(pea, ref_y)),
              conj2(unify(red, ref_x), unify(bean, ref_y))),
              unify(cons(ref_x, cons(ref_y, cons(soup))), ref_r)]
          goal = Fresh.build_goal(['x', 'y'], subgoals)
          expect(goal).to be_kind_of(Core::Goal)
          expect(goal.relation).to be_kind_of(Fresh)
          expect(goal.actuals[0]).to eq(['x', 'y']) # local variable names
          expect(goal.actuals[1]).to be_kind_of(Core::Goal)

          # Check that the created Conj2 is correct
          expect(goal.actuals[1].relation).to eq(Conj2.instance)
          expect(goal.actuals[1].actuals[0]).to eq(subgoals[0])
          expect(goal.actuals[1].actuals[1]).to eq(subgoals[1])
        end
      end # context
    end # describe
  end # module
end # module