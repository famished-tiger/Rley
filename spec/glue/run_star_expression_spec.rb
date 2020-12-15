# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

require_relative '../../lib/mini_kraken/core/all_core'
require_relative '../../lib/mini_kraken/rela/all_rela'
require_relative '../support/factory_atomic'
# require_relative '../support/factory_methods'

# Load the class under test
require_relative '../../lib/mini_kraken/glue/run_star_expression'


module MiniKraken
  module Glue
    describe RunStarExpression do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:pod) { k_symbol(:pod) }
      let(:sample_goal) { unify_goal(pea, pod) }
      let(:fails) { Core::Goal.new(Core::Fail.instance, []) }
      let(:succeeds) { Core::Goal.new(Core::Succeed.instance, []) }
      subject { RunStarExpression.new('q', sample_goal) }

      def unify_goal(arg1, arg2)
        Core::Goal.new(Rela::Unify.instance, [arg1, arg2])
      end

      context 'Initialization:' do
        it 'could be initialized with a name and a goal' do
          expect { RunStarExpression.new('q', sample_goal) }.not_to raise_error
        end

        it 'could be initialized with multiple names and a goal' do
          expect { RunStarExpression.new(%w[r x y], sample_goal) }.not_to raise_error
        end

        # it 'could be initialized with multiple names and goals' do
          # expect { RunStarExpression.new(%w[r x y], [succeeds, succeeds]) }.not_to raise_error
        # end

        it 'should know its variables' do
          definitions = subject.ctx.symbol_table.current_scope.defns
          expect(definitions['q']).not_to be_nil
          expect(definitions.values[0].name).to eq('q')
        end

        it 'should know its goal' do
          expect(subject.goal).to eq(sample_goal)
        end
      end # context

      context 'Provided services:' do
        let(:k_false) { k_boolean(false) }
        let(:k_true) { k_boolean(true) }
        let(:bean) { k_symbol(:bean) }
        let(:corn) { k_symbol(:corn) }
        let(:cup) { k_symbol(:cup) }
        let(:green) { k_symbol(:green) }
        let(:lentil) { k_symbol(:lentil) }
        let(:meal) { k_symbol(:meal) }
        let(:oil) { k_symbol(:oil) }
        let(:olive) { k_symbol(:olive) }
        let(:red) { k_symbol(:red) }
        let(:soup) { k_symbol(:soup) }
        let(:split) { k_symbol(:split) }
        let(:tea) { k_symbol(:tea) }
        let(:virgin) { k_symbol(:virgin) }
        let(:ref_q) { Core::LogVarRef.new('q') }
        let(:ref_r) { Core::LogVarRef.new('r') }
        let(:ref_x) { Core::LogVarRef.new('x') }
        let(:ref_y) { Core::LogVarRef.new('y') }
        let(:ref_z) { Core::LogVarRef.new('z') }
        let(:ref_s) { Core::LogVarRef.new('s') }
        let(:ref_t) { Core::LogVarRef.new('t') }
        let(:ref_u) { Core::LogVarRef.new('u') }
        let(:ref_z) { Core::LogVarRef.new('z') }
        let(:t_ref) { Core::FormalRef.new('t') }

        # @return [Core::Goal]
        def fresh(names, subgoal)
          puts "#{__callee__} #{names}"
          if names.kind_of?(Array)
            k_names = names.map { |nm| Atomic::KString.new(nm) }
          else
            k_names = Atomic::KString.new(names)
          end
          Core::Goal.new(Rela::Fresh.instance, [k_names, subgoal])
        end

        def conj2(term1, term2)
           Core::Goal.new(Rela::Conj2.instance, [term1, term2])
        end

        def unify(term1, term2)
           Core::Goal.new(Rela::Unify.instance, [term1, term2])
        end



        it 'should return a null list with the fail goal' do
          # Reasoned S2, frame 1:7
          # (run* q #u) ;; => ()
          failing = Core::Goal.new(Core::Fail.instance, [])
          instance = RunStarExpression.new('q', failing)

          expect(instance.run).to be_null
        end

        it 'should return a null list with a failing goal' do
          # Reasoned S2, frame 1:10
          # (run* q (== 'pea 'pod)) ;; => ()
          instance = RunStarExpression.new('q', unify(pea, pod))

          expect(instance.run).to be_null
        end

        it 'should return a _0 with the succeed goal' do
          # Reasoned S2, frame 1:17
          # (run* q #s) ;; => (_0)
          success = Core::Goal.new(Core::Succeed.instance, [])
          instance = RunStarExpression.new('q', success)

          expect(instance.run.to_s).to eq('(_0)')
        end

        it 'should return a value with a succeeding goal and q bound' do
          # Reasoned S2, frame 1:11
          # (run* q (== q 'pea)) ;; => (pea)
          instance = RunStarExpression.new('q', unify(ref_q, pea))

          expect(instance.run.to_s).to eq('(:pea)')
        end

        it 'should return a _0 with a succeeding goal and q fresh' do
          # Reasoned S2, frame 1:11
          # (run* q (== q q)) ;; => (_0)
          instance = RunStarExpression.new('q', unify(ref_q, ref_q))

          expect(instance.run.to_s).to eq('(_0)')
        end

        it 'should support the fresh form to nest scopes' do
          # Reasoned S2, frame 1:21
          # (run* q (fresh (x) (== 'pea q))) ;; => (pea)
          subgoal = unify(pea, ref_q)
          instance = RunStarExpression.new('q', fresh('x', subgoal))

          expect(instance.run.to_s).to eq('(:pea)')
        end

        it 'should support conjunction of two succeed' do
          # Reasoned S2, frame 1:50
          # (run* q (conj2 succeed succeed)) ;; => (_0)
          goal = conj2(succeeds, succeeds)
          instance = RunStarExpression.new('q', goal)

          result = instance.run
          expect(result.to_s).to eq('(_0)')
        end

        it 'should support conjunction of one succeed and a successful goal' do
          # Reasoned S2, frame 1:51
          # (run* q (conj2 succeed (== 'corn q)) ;; => ('corn)
          subgoal = unify(corn, ref_q)
          instance = RunStarExpression.new('q', conj2(succeeds, subgoal))

          result = instance.run
          expect(result.to_s).to eq('(:corn)')
        end

        # TODO: add two solutions case
        # TODO: add fused variables
      end # context
    end # describe
  end # module
end # module
