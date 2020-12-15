# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/all_core'

require_relative '../support/factory_atomic'
require_relative '../support/factory_composite'
require_relative '../../lib/mini_kraken/rela/disj2'
require_relative '../../lib/mini_kraken/rela/unify'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/def_relation'

module MiniKraken
  module Rela
    describe DefRelation do
      include MiniKraken::FactoryAtomic # Use mix-in module
      include MiniKraken::FactoryComposite # Use mix-in module

      # (defrel (teacupo t) (disj2 (== 'tea t) (== 'cup t)))
      let(:tea) { k_symbol(:tea) }
      let(:cup) { k_symbol(:cup) }
      let(:formal_t) { 't' }
      let(:t_ref) { Core::LogVarRef.new('t') }
      let(:equals_tea) { unify_goal(tea, t_ref) }
      let(:equals_cup) { unify_goal(cup, t_ref) } 
      let(:goal_template) { disj2_goal(equals_tea, equals_cup) }
      let(:ctx) { Core::Context.new }
      let(:uuid_pattern) do 
        /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
      end
      
      subject { DefRelation.new('teacupo', goal_template, [formal_t]) }

      def unify_goal(term1, term2)
        Core::Goal.new(Unify.instance, [term1, term2])
      end

      def disj2_goal(term1, term2)
        Core::Goal.new(Disj2.instance, [term1, term2])
      end

      context 'Initialization:' do
        it 'should be initialized with a name, a goal template, formal args' do
          expect do 
            DefRelation.new('teacupo', goal_template, [formal_t]) 
          end.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('teacupo')
        end

        it 'should know its goal expression' do
          expect(subject.expression).to be_kind_of(Core::Goal)
          expect(subject.expression.relation).to eq(Disj2.instance)
          
          g1 = subject.expression.actuals[0]
          expect(g1).to be_kind_of(Core::Goal)
          expect(g1.relation).to eq(Unify.instance)
          expect(g1.actuals[0]).to eq(tea)
          expect(g1.actuals[1]).to be_kind_of(Core::LogVarRef)
          expect(g1.actuals[1].name).to match(/^t_/)          
          expect(g1.actuals[1].name).to match(uuid_pattern)
          
          g2 = subject.expression.actuals[1]
          expect(g2).to be_kind_of(Core::Goal)
          expect(g2.relation).to eq(Unify.instance)
          expect(g2.actuals[0]).to eq(cup)
          expect(g2.actuals[1]).to be_kind_of(Core::LogVarRef)          
          expect(g2.actuals[1].name).to match(/^t_/)          
          expect(g2.actuals[1].name).to match(uuid_pattern)         
        end

        it 'should know its formals' do
          expect(subject.formals[0]).to match(/^t_/)
          expect(subject.formals[0]).to match(uuid_pattern)
        end
        
        it 'should bear an internal name' do
          expect { subject.i_name }.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'should provide solver for a single-node goal without ref actual' do
          defrel = DefRelation.new('teao', equals_tea, [formal_t])
          solver = defrel.solver_for([tea], ctx)
          outcome = solver.resume
          expect(outcome).to be_success
          outcome = solver.resume
          expect(outcome).to be_nil

          solver = defrel.solver_for([cup], ctx)
          outcome = solver.resume
          expect(outcome).not_to be_success
          outcome = solver.resume
          expect(outcome).to be_nil
        end
        
        it 'should provide solver for a multiple-nodes goal with ref actual' do
          expr = disj2_goal(equals_tea, equals_cup)
          defrel = DefRelation.new('teacupo', expr, [formal_t])
          x_ref = Core::LogVarRef.new('x')
          ctx.add_vars(['x'])
          solver = defrel.solver_for([x_ref], ctx)
          [tea, cup].each do |predicted|
            outcome = solver.resume
            expect(outcome).to be_success
            sol = ctx.build_solution
            expect(sol['x']).to eq(predicted)
          end
          outcome = solver.resume
          expect(outcome).to be_nil
        end                
      end # context
    end # describe
  end # module
end # module