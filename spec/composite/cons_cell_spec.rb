# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/context'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'

# Load the class under test
require_relative '../../lib/mini_kraken/composite/cons_cell'

module MiniKraken
  module Composite
    describe ConsCell do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:pod) { k_symbol(:pod) }
      let(:corn) { k_symbol(:corn) }
      let(:ctx) { Core::Context.new }
      subject { ConsCell.new(pea, pod) }

      context 'Initialization:' do
        it 'could be initialized with one argument' do
          expect { ConsCell.new(pea) }.not_to raise_error
        end

        it 'could be initialized with a second optional argument' do
          expect { ConsCell.new(pea, pod) }.not_to raise_error
        end

        it 'could be initialized as null list' do
          expect { ConsCell.null }.not_to raise_error
        end

        it 'should know its car child' do
          expect(subject.car).to eq(pea)
        end

        it 'should know its cdr child' do
          expect(subject.cdr).to eq(pod)
        end


        it 'should know its children' do
          expect(subject.children).to eq([pea, pod])
        end

        it 'should know if it is empty (null)' do
          expect(subject).not_to be_null
          expect(ConsCell.new(nil, nil)).to be_null
          expect(ConsCell.null).to be_null
          expect(NullList).to be_null
        end

        it 'simplifies cdr if its referencing a null list' do
          instance = ConsCell.new(pea, NullList)
          expect(instance.car).to eq(pea)
          expect(instance.cdr).to be_nil
        end
      end # context

      context 'Provided services:' do
        it 'should compare to itself' do
          expect(subject.eql?(subject)).to be_truthy
          synonym = subject
          expect(subject == synonym).to be_truthy
        end

        it 'should compare to another instance' do
          same = ConsCell.new(pea, pod)
          expect(subject.eql?(same)).to be_truthy

          different = ConsCell.new(pod, pea)
          expect(subject.eql?(different)).to be_falsey

          different = ConsCell.new(pea)
          expect(subject.eql?(different)).to be_falsey
        end

        it 'should set_car! another cons cell' do
          instance = ConsCell.new(pea)
          head = ConsCell.new(pod)
          instance.set_car!(head)
          expect(instance.car).to eq(head)
          expect(instance.cdr).to be_nil
        end

        it 'should set_cdr! another cons cell' do
          instance = ConsCell.new(pea)
          trail = ConsCell.new(pod)
          instance.set_cdr!(trail)
          expect(instance.car).to eq(pea)
          expect(instance.cdr).to eq(trail)
        end

        it 'should set a member to some term' do
          instance = ConsCell.null
          head = ConsCell.new(pea)
          trail = ConsCell.new(pod)
          instance.set!(:car, head)
          instance.set!(:cdr, trail)
          expect(instance.car).to eq(head)
          expect(instance.cdr).to eq(trail)
        end

        it 'should know whether it is pinned or not' do
          # Case: all pair members are atomic items
          expect(subject).to be_pinned(ctx)

          # Case: cdr is nil
          instance = ConsCell.new(pea)
          expect(instance).to be_pinned(ctx)

          # Case: embedded composite
          nested = ConsCell.new(ConsCell.new(pod, pea), ConsCell.new(pea))
          expect(nested).to be_pinned(ctx)

          ctx.add_vars('q')
          nested.set_cdr!(Core::LogVarRef.new('q'))
          expect(nested).not_to be_pinned(ctx)
          expect(nested).to be_floating(ctx)

          ctx.associate('q', ConsCell.new(pea))
          expect(nested).to be_pinned(ctx)
        end

        it 'should provide a list representation of itself' do
          # Case of null list
          expect(NullList.to_s).to eq '()'

          # Case of one element proper list
          cell = ConsCell.new(pea)
          expect(cell.to_s).to eq '(:pea)'

          # Case of two elements proper list
          cell = ConsCell.new(pea, ConsCell.new(pod))
          expect(cell.to_s).to eq '(:pea :pod)'

          # Case of two elements improper list
          expect(subject.to_s).to eq '(:pea . :pod)'

          # Case of one element plus null list
          cell = ConsCell.new(pea)
          cell.set_cdr!(ConsCell.null)
          expect(cell.to_s).to eq '(:pea)'

          # Case of three elements proper list
          cell = ConsCell.new(pea, ConsCell.new(pod, ConsCell.new(corn)))
          expect(cell.to_s).to eq '(:pea :pod :corn)'

          # Case of three elements improper list
          cell = ConsCell.new(pea, ConsCell.new(pod, corn))
          expect(cell.to_s).to eq '(:pea :pod . :corn)'

          # Case of a nested list
          cell = ConsCell.new(ConsCell.new(pea), ConsCell.new(pod))
          expect(cell.to_s).to eq '((:pea) :pod)'
        end

        it 'should know its dependencies' do
          # Case: no var ref...
          lst = ConsCell.new(ConsCell.new(pod, pea), ConsCell.new(pea))
          expect(lst.dependencies(ctx)).to be_empty

          # Case: multiple var refs
          ctx.add_vars(['q', 'x'])
          q_ref = Core::LogVarRef.new('q')
          x_ref = Core::LogVarRef.new('x')
          list2 = ConsCell.new(ConsCell.new(q_ref, pea), ConsCell.new(x_ref))
          expect(list2.dependencies(ctx).size).to eq(2)
          q_var = ctx.lookup('q')
          x_var = ctx.lookup('x')
          predicted = Set.new([q_var.i_name, x_var.i_name])
          expect(list2.dependencies(ctx)).to eq(predicted)
        end

        it 'should, as list with atomic terms, provide an expanded copy' do
          # Case of a list of atomic terms
          lst = ConsCell.new(ConsCell.new(ConsCell.new(pea), pod))
          representation = lst.to_s

          copy = lst.expand(ctx, {})
          expect(copy.to_s).to eq(representation)
        end

        it 'should, as list with variable refs, provide an expanded copy' do
          # Case of a list of variable refs
          ctx.add_vars(['x'])
          x_ref = Core::LogVarRef.new('x')
          x_var = ctx.lookup('x')
          ctx.associate('x', Core::AnyValue.new(0))
          lst = ConsCell.new(x_ref, ConsCell.new(x_ref))
          substitutions = {}
          substitutions[x_var.i_name] = Core::AnyValue.new(0)

          copy = lst.expand(ctx, substitutions)
          expect(copy.to_s).to eq('(_0 _0)')
        end

        it 'should provide a duplicate with variable replaced by their value' do
          q_ref = Core::LogVarRef.new('q')
          x_ref = Core::LogVarRef.new('x')
          y_ref = Core::LogVarRef.new('y')
          substitutions = {
            'q' => ConsCell.new(pea, ConsCell.new(x_ref, y_ref)),
            'x' => pod,
            'y' => corn
          }

          # Basic case: variable ref points to an atomic value
          expr = ConsCell.new(pea, x_ref)
          duplicate = expr.dup_cond(substitutions)
          expect(duplicate.to_s).to eq('(:pea . :pod)')

          expr = ConsCell.new(pod, ConsCell.new(q_ref, y_ref))
          duplicate = expr.dup_cond(substitutions)
          expect(duplicate.car).to eq(pod)
          expect(duplicate.cdr.car.to_s).to eq('(:pea :pod . :corn)')
          expect(duplicate.to_s).to eq('(:pod (:pea :pod . :corn) . :corn)')
        end
      end # context
    end # describe
  end # module
end # module
