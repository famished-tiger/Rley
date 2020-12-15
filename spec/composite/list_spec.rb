# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'

# Load the class under test
require_relative '../../lib/mini_kraken/composite/list'

module MiniKraken
  module Composite
    describe List do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:pod) { k_symbol(:pod) }
      let(:corn) { k_symbol(:corn) }

      context 'Module as a factory:' do
        subject { List }

        it 'builds a pair wiht one argument (= one element proper list)' do
          pair = subject.cons(pea)
          expect(pair.car).to eq(pea)
          expect(pair.cdr).to be_nil
        end

        it 'builds a pair with two explicit arguments' do
          pair = subject.cons(pea, pod)
          expect(pair.car).to eq(pea)
          expect(pair.cdr).to eq(pod)
        end

        it 'builds a null list from an empty array' do
          l = subject.make_list([])
          expect(l).to be_kind_of(ConsCell)
          expect(l).to be_null
        end

        it 'builds a proper list from an non-empty array' do
          l = subject.make_list([pea, pod, corn])

          expect(l.car).to eq(pea)
          expect(l.cdr.car).to eq(pod)
          expect(l.cdr.cdr.car).to eq(corn)
          expect(l.cdr.cdr.cdr).to be_nil
        end
      end # context
    end # describz
  end # module
end # module
