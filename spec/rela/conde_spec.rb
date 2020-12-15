# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/fail'
require_relative '../../lib/mini_kraken/core/succeed'
require_relative '../../lib/mini_kraken/core/context'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'
require_relative '../../lib/mini_kraken/rela/unify'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/conde'

module MiniKraken
  module Rela
    describe Conde do
      include MiniKraken::FactoryAtomic # Use mix-in module

      subject { Conde.instance }

      context 'Initialization:' do
        it 'should be initialized without argument' do
          expect { Conde.instance }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('conde')
        end
      end # context

      context 'Provided services:' do

        let(:bean) { k_symbol(:bean) }
        let(:corn) {k_symbol(:corn) }
        let(:meal) { k_symbol(:meal) }
        let(:oil) { k_symbol(:oil) }
        let(:olive) { k_symbol(:olive) }
        let(:pea) { k_symbol(:pea) }
        let(:red) { k_symbol(:red) }
        let(:split) { k_symbol(:split) }
        let(:fails) { Core::Goal.new(Core::Fail.instance, []) }
        let(:succeeds) { Core::Goal.new(Succeed.instance, []) }
        let(:var_q) { Core::LogVar.new('q') }
        let(:var_x) { Core::LogVar.new('x') }
        let(:var_y) { Core::LogVar.new('y') }
        let(:ref_q) { Core::LogVarRef.new('q') }
        let(:ref_x) { Core::LogVarRef.new('x') }
        let(:ref_y) { Core::LogVarRef.new('y') }
        let(:ctx) do
          e = Core::Context.new
          e.add_vars(['q', 'x', 'y'])

          e
        end

        it 'should complain when one of its argument is not a goal' do
          err = StandardError
          expect { subject.solver_for([succeeds, pea], ctx) }.to raise_error(err)
          expect { subject.solver_for([pea, succeeds], ctx) }.to raise_error(err)
        end

        it 'should fail when all goals fail' do
          solver = subject.solver_for([fails, fails, fails], ctx)
          expect(solver.resume).not_to be_success
          expect(solver.resume).to be_nil
        end

        it 'yield success if first argument succeeds' do
          subgoal = Core::Goal.new(Unify.instance, [olive, ref_q])
          solver = subject.solver_for([subgoal, fails, fails], ctx)
          outcome = solver.resume

          expect(outcome).to be_success
          sol = outcome.build_solution
          expect(sol['q']).to eq(olive)
          expect(solver.resume).to be_nil
        end

        it 'yield success if second argument succeeds' do
          subgoal = Core::Goal.new(Unify.instance, [oil, ref_q])
          solver = subject.solver_for([fails, subgoal, fails], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          sol = outcome.build_solution
          expect(sol['q']).to eq(oil)          
          expect(solver.resume).to be_nil
        end

        it 'yield success if third argument succeeds' do
          subgoal = Core::Goal.new(Unify.instance, [oil, ref_q])
          solver = subject.solver_for([fails, fails, subgoal], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          expect(outcome.build_solution['q']).to eq(oil)
          expect(solver.resume).to be_nil
        end

        it 'yields three solutions if three goals succeed' do
          # Covers frame 1:58
          subgoal1 = Core::Goal.new(Unify.instance, [olive, ref_q])
          subgoal2 = Core::Goal.new(Unify.instance, [oil, ref_q])
          subgoal3 = Core::Goal.new(Unify.instance, [pea, ref_q])
          solver = subject.solver_for([subgoal1, subgoal2, subgoal3, fails], ctx)

          # First solution
          outcome1 = solver.resume
          expect(outcome1).to be_success
          expect(outcome1.build_solution['q']).to eq(olive)

          # Second solution
          outcome2 = solver.resume
          expect(outcome2).to be_success
          expect(outcome2.build_solution['q']).to eq(oil)

          # Third solution
          outcome3 = solver.resume
          expect(outcome3).to be_success
          expect(outcome3.build_solution['q']).to eq(pea)

          expect(solver.resume).to be_nil
        end

        it 'also use conjunctions for nested goals' do
          # Covers frame 1:88
          subgoal1 = Core::Goal.new(Unify.instance, [split, ref_x])
          subgoal2 = Core::Goal.new(Unify.instance, [pea, ref_y])
          combo1 = [subgoal1, subgoal2]

          subgoal3 = Core::Goal.new(Unify.instance, [red, ref_x])
          subgoal4 = Core::Goal.new(Unify.instance, [bean, ref_y])
          combo2 = [subgoal3, subgoal4]
          solver = subject.solver_for([combo1, combo2], ctx)

          # First solution
          outcome1 = solver.resume
          expect(outcome1).to be_success
          solution1 = outcome1.build_solution
          expect(solution1['x']).to eq(split)
          expect(solution1['y']).to eq(pea)

          # Second solution
          outcome2 = solver.resume        
          expect(outcome2).to be_success
          solution2 = outcome2.build_solution            
          expect(solution2['x']).to eq(red)
          expect(solution2['y']).to eq(bean)

          expect(solver.resume).to be_nil
        end
      end # context
    end # describe
  end # module
end # module
