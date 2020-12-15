# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'

require_relative '../support/factory_atomic'
require_relative '../support/factory_composite'

# Load the class under test
require_relative '../../lib/mini_kraken/rela/unify'

module MiniKraken
  module Rela
    describe Unify do
      include MiniKraken::FactoryAtomic # Use mix-in module
      include MiniKraken::FactoryComposite # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:pea2) { k_symbol(:pea) } # Same value but distinct object
      let(:pod) { k_symbol(:pod) }
      let(:null) { cons(nil, nil) }
      let(:q_ref) { Core::LogVarRef.new('q') }
      let(:ctx) { Core::Context.new }
      subject { Unify.instance }

      def var(aName)
        Core::LogVar.new(aName)
      end

      # Convenience method to factor out repeated statements
      def solve(arg1, arg2)
        solver = subject.solver_for([arg1, arg2], ctx)
        solver.resume(ctx)
      end

      before(:each) do
        ctx.insert(var('q'))
      end

      context 'Initialization:' do
        it 'should know its relation name' do
          expect(subject.name).to eq('unify')
        end

        it 'should know its arity (binary)' do
          expect(subject.arity).to be_binary
        end

        it 'should be frozen' do
          expect(subject).to be_frozen
        end
      end # context

      context 'Unifying identical or nil terms:' do
        it 'should succeed for identical arguments' do
          term = double('anything')
          result = solve(term, term)

          expect(result).to be_kind_of(Core::Context)
          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it 'should succeed for two nil arguments' do
          result = solve(nil, nil)
          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it 'should fail for one nil and one non-nil argument' do
          term = double('anything')
          result = solve(term, nil)
          expect(result).to be_failure

          # Check symmetry
          result = solve(nil, term)
          expect(result).to be_failure
        end
      end # context

      context 'Unifying atomic terms:' do
        it 'should unify symbols of same value' do
          # Identical literals
          result = solve(pea, pea)
          expect(result).to be_success

          pea_bis = k_symbol(:pea)
          result = solve(pea, pea_bis)
          expect(result).to be_success
          expect(result.blackboard).to be_empty

          true_a = k_boolean(false)
          true_b = k_boolean(false)
          result = solve(true_a, true_b)
          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it 'should fail for atomic terms with different values' do
          result = solve(pea, pod)
          expect(result).to be_failure

          true_t = k_boolean(true)
          false_t = k_boolean(false)
          result = solve(true_t, false_t)
          expect(result).to be_failure
        end
      end # context

      context 'Unifying composite with atomic term:' do
        it 'should fail to unify a composite to an atomic term' do
          pair = cons(double('car-fake'), double('cdr-fake'))

          result = solve(pair, pea)
          expect(result).to be_failure
          expect(result.blackboard).to be_empty

          # Check symmetry
          result = solve(pea, pair)
          expect(result).to be_failure
          expect(result.blackboard).to be_empty
        end
      end # context

      context 'Unifying null list with a term:' do
        it 'should unify two null lists' do
          null2 = cons(nil, nil)

          result = solve(null, null2)
          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it "shouldn't unify a null list with any non null composite" do
          # Fail to unify null with a non-null list
          list1 = make_list(double('dummy'))
          result = solve(null, list1)

          expect(result).to be_failure

          # Check symmetry
          result = solve(list1, null)
          expect(result).to be_failure
        end

        it 'should unify null list with fresh variable' do
          result = solve(null, q_ref)

          expect(result).to be_success
          expect(result.blackboard).not_to be_empty
          expect(result.associations_for('q').first.value).to eq(null)
        end

        it 'should unify null list with variable bound to null list' do
          solve(null, q_ref) # q is bound to null list

          # Attempting to unify again null list with same variable is OK
          result = solve(null, q_ref)
          expect(result).to be_success

          # Success, but no redundant association is created...
          expect(result.blackboard.move_queue.size).to eq(1)
        end

        it "shouldn't unify a null list with a variable bound to atomic" do
          ctx.associate('q', pea)
          result = solve(null, q_ref)
          expect(result).to be_failure
        end

        it "shouldn't unify a null list with a variable bound to composite" do
          ctx.associate('q', cons(pea))
          result = solve(null, q_ref)
          expect(result).to be_failure
        end
      end # context

      context 'Unifying two non-null composite terms:' do
        it 'should unify two one-element lists with same atomic terms' do
          list_pea = cons(pea)
          list_pea2 = cons(pea2)
          result = solve(list_pea, list_pea2)

          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it "shoudn't unify two one-element lists with unequal atomic terms" do
          list_pea = cons(pea)
          list_pod = cons(pod)
          result = solve(list_pea, list_pod)

          expect(result).to be_failure
        end

        it 'should unify two pairs with same atomic terms' do
          pair1 = cons(pea, pea)
          pair2 = cons(pea, pea2)
          result = solve(pair1, pair2)

          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it "shoudn't unify two pairs with unequal atomic terms" do
          pair_a = cons(pea, pea)
          pair_b = cons(pea, pod)
          result = solve(pair_a, pair_b)

          expect(result).to be_failure
        end

        it 'should unify two element lists with same atomic terms' do
          # Two element lists
          list_a = make_list(pea, pea)
          list_b = make_list(pea, pea2)
          result = solve(list_a, list_b)

          expect(result).to be_success
          expect(result.blackboard).to be_empty
        end

        it "shoudn't unify two element lists with with unequal atomic terms" do
          # Two element lists
          list_a = make_list(pea, pea)
          list_b = make_list(pea, pod)
          result = solve(list_a, list_b)

          expect(result).to be_failure
        end

        it 'should unify composites with one fresh variable' do
          list_a = make_list(pea, pod)
          list_b = make_list(pea, q_ref)
          result = solve(list_a, list_b)

          expect(result).to be_success
          expect(result.blackboard.move_queue.size).to eq(1)
          expect(ctx.associations_for('q').first.value).to eq(pod)
        end

        it 'should unify composites with redundant unification' do
          list_a = make_list(pea, pea2, pod)

          # Twist: q is paired twice to :pea, which is OK
          list_b = make_list(q_ref, q_ref, pod)
          result = solve(list_a, list_b)

          expect(result).to be_success

          # Only one association is created...
          expect(result.blackboard.move_queue.size).to eq(1)
          expect(ctx.associations_for('q').first.value).to eq(pea)
        end

        it 'should unify composites with same variables at same positions' do
          # Case: q is a fresh variable
          q_ref2 = Core::LogVarRef.new('q') # Other ref to same variable
          list_a = make_list(pea, pod, q_ref)
          list_b = make_list(pea, pod, q_ref2)
          result = solve(list_a, list_b)

          expect(result).to be_success
          expect(result.blackboard).to be_empty # No association created

          # Case: q is a bound variable
          ctx.associate('q', pea)
          expect(ctx.blackboard.move_queue.size).to eq(1)
          result = solve(list_a, list_b)

          expect(result).to be_success
          expect(ctx.blackboard.move_queue.size).to eq(1) # No new association
        end
      end # context


      context 'Unifying variable with atomic term:' do
        it 'should unify a fresh variable to an atomic term' do
          result = solve(q_ref, pea)

          expect(result).to be_success
          expect(result.blackboard).not_to be_empty
          expect(ctx.associations_for('q').size).to eq(1)
          expect(ctx.associations_for('q').first.value).to eq(pea)
        end

        it 'should unify a left-handed bound variable to the same atomic t.' do
          solve(q_ref, pea)
          result = solve(q_ref, pea) # Try to associate with 'pea' again...
          expect(result).to be_success

          # But no redundant association is created...
          expect(ctx.associations_for('q').size).to eq(1)
        end

        it 'should unify a right-handed bound variable to the same atomic t.' do
          solve(pea, q_ref)
          result = solve(pea, q_ref) # Try to associate with 'pea' again...
          expect(result).to be_success

          # No redundant association was added...
          expect(ctx.associations_for('q').size).to eq(1)
        end

        it "shouldn't unify a variable bound to another atomic term" do
          solve(q_ref, pea) # q will be bound to :pea

          # Trying a second time with another value should fail...
          result = solve(q_ref, pod)
          expect(result).to be_failure # Side effect: associations are removed
          expect(result.blackboard).to be_empty
        end
      end # context


      context 'Unifying variable with composite term:' do
        it 'should unify a fresh variable to a composite term' do
          list = make_list(pea, pod)
          result = solve(q_ref, list)

          expect(result).to be_success
          expect(result.blackboard).not_to be_empty
          expect(ctx.associations_for('q').size).to eq(1)
          expect(ctx.associations_for('q').first.value).to eq(list)
        end

        it 'should unify a bound variable again with equal composite' do
          list_a = make_list(cons(pea, pod), pea2)
          list_b = make_list(cons(pea2, pod), pea)
          result = solve(q_ref, list_a)

          expect(result).to be_success
          expect(result.blackboard).not_to be_empty
          expect(ctx.associations_for('q').first.value).to eq(list_a)

          result = solve(q_ref, list_b)
          expect(result).to be_success
          expect(ctx.associations_for('q').size).to eq(1)
        end

        it "shouldn't unify a bound variable to something different" do
          list_a = make_list(cons(pea, pod), pea2)
          solve(q_ref, list_a)

          list_b = make_list(cons(pod, pod), pea)
          result = solve(q_ref, list_b)
          expect(result).to be_failure
        end
      end # context

      context 'Unifying variable with another one:' do
        it 'should unify one left-handed fresh variable to a bound variable' do
          liste = make_list(cons(pea, pod), pea2)
          solve(q_ref, liste)

          ctx.add_vars('x')
          x_ref = Core::LogVarRef.new('x')
          result = solve(x_ref, q_ref)
          queue = result.blackboard.move_queue

          expect(queue[-2]).to be_kind_of(Core::Fusion)
          expect(queue[-1]).to be_kind_of(Core::AssociationCopy)
          expect(queue[-1].value).to be_equal(liste)
        end
      end # context
    end # describe
  end # module
end # module
