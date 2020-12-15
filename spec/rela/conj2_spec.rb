# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/all_core'

require_relative '../support/factory_atomic'
require_relative '../support/factory_composite'
require_relative '../../lib/mini_kraken/rela/unify'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/conj2'

module MiniKraken
  module Rela
    describe Conj2 do
      include MiniKraken::FactoryAtomic # Use mix-in module
      include MiniKraken::FactoryComposite # Use mix-in module
      subject { Conj2.instance }


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
          expect(subject.name).to eq('conj2')
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
        let(:pea) { k_symbol(:pea) }
        let(:corn) { k_symbol(:corn) }
        let(:meal) { k_symbol(:meal) }
        let(:fails) { Core::Goal.new(Core::Fail.instance, []) }
        let(:succeeds) { Core::Goal.new(Core::Succeed.instance, []) }
        let(:var_q) { var('q') }
        let(:ref_q) { Core::LogVarRef.new('q') }
        
        def unify(term1, term2)
           Core::Goal.new(Unify.instance, [term1, term2])
        end
        
        before(:each) { ctx.add_vars('q')  }

        it 'should complain when one of its argument is not a goal' do
          err = StandardError
          expect { subject.solver_for([succeeds, pea], ctx) }.to raise_error(err)
          expect { subject.solver_for([pea, succeeds], ctx) }.to raise_error(err)
        end

        it 'should yield one failure if one of the goal is fail' do
          # Fail as first argument
          solver = subject.solver_for([fails, succeeds], ctx)
          expect(solver.resume).not_to be_success
          expect(solver.resume).to be_nil

          # Fail as second argument
          solver = subject.solver_for([succeeds, fails], ctx)
          expect(solver.resume).not_to be_success
          expect(solver.resume).to be_nil
        end

        it 'yield success if both arguments are succeed goals' do
          solver = subject.solver_for([succeeds, succeeds], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.blackboard).to be_empty
          expect(solver.resume).to be_nil
        end
        
        it 'should yield success and set associations' do
          solver = subject.solver_for([succeeds, unify(corn, ref_q)], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.blackboard).not_to be_empty
          expect(outcome.associations_for('q').first.value).to eq(corn)
        end

        it 'should yield fails and set no associations' do
          solver = subject.solver_for([fails, unify(corn, ref_q)], ctx)
          outcome = solver.resume
          expect(outcome).not_to be_success
          expect(outcome.blackboard).to be_empty          
        end

        it 'should yield fails when sub-goals are incompatible' do
          sub_goal1 = unify(corn, ref_q)
          sub_goal2 = unify(meal, ref_q)
          solver = subject.solver_for([sub_goal1, sub_goal2], ctx)
          outcome = solver.resume
          expect(outcome).not_to be_success
          expect(outcome.blackboard).to be_empty    
        end

        it 'should yield success when sub-goals are same and successful' do
          sub_goal1 = unify(corn, ref_q)
          sub_goal2 = unify(ref_q, corn)
          solver = subject.solver_for([sub_goal1, sub_goal2], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.blackboard).not_to be_empty
          expect(outcome.associations_for('q').first.value).to eq(corn)
        end        
      end # context
    end # describe
  end # module
end # module