# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/all_core'

require_relative '../support/factory_atomic'
require_relative '../support/factory_composite'
require_relative '../../lib/mini_kraken/rela/unify'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/disj2'

module MiniKraken
  module Rela
    describe Disj2 do
      include MiniKraken::FactoryAtomic # Use mix-in module
      include MiniKraken::FactoryComposite # Use mix-in module
      subject { Disj2.instance }

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
          expect(subject.name).to eq('disj2')
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
        let(:oil) { k_symbol(:oil) }
        let(:olive) { k_symbol(:olive) }        
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


        it 'should fails if both arguments fail' do
          # Covers frame 1:55
          solver = subject.solver_for([fails, fails], ctx)
          expect(solver.resume).not_to be_success
          expect(solver.resume).to be_nil
        end

        it 'yield success if first argument succeeds' do
          # Covers frame 1:56
          subgoal = Core::Goal.new(Unify.instance, [olive, ref_q])
          solver = subject.solver_for([subgoal, fails], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.associations_for('q').first.value).to eq(olive)
          expect(solver.resume).to be_nil
        end

        it 'yield success if second argument succeeds' do
          # Covers frame 1:57
          subgoal = Core::Goal.new(Unify.instance, [oil, ref_q])
          solver = subject.solver_for([fails, subgoal], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.associations_for('q').first.value).to eq(oil)
          expect(solver.resume).to be_nil
        end

        it 'yield two solutions if both arguments succeed' do
          # Covers frame 1:58
          subgoal1 = Core::Goal.new(Unify.instance, [olive, ref_q])
          subgoal2 = Core::Goal.new(Unify.instance, [oil, ref_q])
          solver = subject.solver_for([subgoal1, subgoal2], ctx)

          # First solution
          outcome1 = solver.resume
          expect(outcome1).to be_success
          expect(outcome1.associations_for('q').first.value).to eq(olive)

          # Second solution
          # require 'debug'
          outcome2 = solver.resume
          expect(outcome2).to be_success
          expect(outcome2.associations_for('q').first.value).to eq(oil)
          expect(solver.resume).to be_nil
        end
      
      end # context
    end # describe
  end # module
end # module