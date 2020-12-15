# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/log_var_ref'

# Load the class under test
require_relative '../../lib/mini_kraken/composite/cons_cell_visitor'

module MiniKraken
  module Composite
    describe ConsCellVisitor do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:pod) { k_symbol(:pod) }
      let(:corn) { k_symbol(:corn) }
      let(:ref_q) { LogVarRef.new('q') }
      let(:l_pea) { ConsCell.new(pea) }
      let(:l_pea_pod) { ConsCell.new(pea, ConsCell.new(pod)) }
      let(:l_pea_pod_corn) { ConsCell.new(pea, ConsCell.new(pod, ConsCell.new(corn))) }
      subject { ConsCellVisitor }

      context 'Provided services:' do
        it 'acts as a factory of Fiber objects' do
          expect(subject.df_visitor(l_pea)).to be_kind_of(Fiber)
        end
      end # context

      context 'proper list visiting:' do
        it 'can visit a null list' do
          null_list = ConsCell.null
          visitor = subject.df_visitor(null_list)
          expect(visitor.resume).to eq([:car, null_list])
          expect(visitor.resume).to eq([:car, nil])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can visit a single element proper list' do
          visitor = subject.df_visitor(l_pea)
          expect(visitor.resume).to eq([:car, l_pea])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can visit a two elements proper list' do
          visitor = subject.df_visitor(l_pea_pod)
          expect(visitor.resume).to eq([:car, l_pea_pod])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, l_pea_pod.cdr])
          expect(visitor.resume).to eq([:car, pod])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can visit a three elements proper list' do
          visitor = subject.df_visitor(l_pea_pod_corn)
          expect(visitor.resume).to eq([:car, l_pea_pod_corn])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, l_pea_pod_corn.cdr])
          expect(visitor.resume).to eq([:car, pod])
          expect(visitor.resume).to eq([:cdr, l_pea_pod_corn.cdr.cdr])
          expect(visitor.resume).to eq([:car, corn])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:stop, nil])
        end
      end # context

      context 'improper list visiting:' do
        it 'can visit a single element improper list' do
          l_improper = ConsCell.new(nil, pea)
          visitor = subject.df_visitor(l_improper)
          expect(visitor.resume).to eq([:car, l_improper])
          expect(visitor.resume).to eq([:car, nil])
          expect(visitor.resume).to eq([:cdr, pea])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can visit a two elements improper list' do
          l_improper = ConsCell.new(pea, pod)
          visitor = subject.df_visitor(l_improper)
          expect(visitor.resume).to eq([:car, l_improper])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, pod])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can visit a three elements improper list' do
          l_improper = ConsCell.new(pea, ConsCell.new(pod, corn))
          expect(l_improper.to_s).to eq('(:pea :pod . :corn)')
          visitor = subject.df_visitor(l_improper)
          expect(visitor.resume).to eq([:car, l_improper])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, l_improper.cdr])
          expect(visitor.resume).to eq([:car, pod])
          expect(visitor.resume).to eq([:cdr, corn])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'smurch' do
          composite = ConsCell.new(ConsCell.new(ConsCell.new(pea)), pod)
          visitor = subject.df_visitor(composite)
          expect(visitor.resume).to eq([:car, composite])
          expect(visitor.resume).to eq([:car, composite.car])
          expect(visitor.resume).to eq([:car, composite.car.car])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:cdr, pod])
        end
      end # context

      context 'Skip visit of children of a ConsCell:' do
        it 'can skip the visit of null list children' do
          null_list = ConsCell.new(nil)
          visitor = subject.df_visitor(null_list)

          # Tell to skip children by passing a true value to resume
          expect(visitor.resume(true)).to eq([:car, null_list])
          expect(visitor.resume).to eq([:stop, nil])
        end

        it 'can skip the visit of some children' do
          tree = ConsCell.new(pea, ConsCell.new(l_pea_pod, ConsCell.new(corn)))
          expect(tree.to_s).to eq('(:pea (:pea :pod) :corn)')
          visitor = subject.df_visitor(tree)
          expect(visitor.resume).to eq([:car, tree])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, tree.cdr])
          expect(visitor.resume).to eq([:car, l_pea_pod])

          # Tell to skip children by passing a true value to resume
          expect(visitor.resume(true)).to eq([:cdr, tree.cdr.cdr])
          expect(visitor.resume).to eq([:car, corn])
          expect(visitor.resume).to eq([:cdr, nil])
          expect(visitor.resume).to eq([:stop, nil])
        end
      end # context

      context 'Circular structures visiting:' do
        it 'should cope with a circular graph' do
          second_cell = ConsCell.new(pea)
          first_cell = ConsCell.new(pea, second_cell)
          second_cell.set_car!(first_cell)

          visitor = subject.df_visitor(first_cell)
          expect(visitor.resume).to eq([:car, first_cell])
          expect(visitor.resume).to eq([:car, pea])
          expect(visitor.resume).to eq([:cdr, second_cell])
          expect(visitor.resume).to eq([:cdr, nil]) # Skip car (was already visited)
          expect(visitor.resume).to eq([:stop, nil])
        end
      end # context
    end # describe
  end # module
end # module
