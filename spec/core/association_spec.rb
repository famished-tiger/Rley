# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/context'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'

# Load the class under test
require_relative '../../lib/mini_kraken/core/association'

module MiniKraken
  module Core
    describe Association do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      subject { Association.new('q', pea) }

      context 'Initialization:' do
        it 'should be initialized with a name and a value' do
          expect { Association.new('q', pea) }.not_to raise_error
        end

        it 'should be initialized with a variable and a value' do
          expect { Association.new(LogVar.new('p'), pea) }.not_to raise_error
        end

        it 'should know the variable name' do
          expect(subject.i_name).to eq('q')
        end

        it 'should know the associated value' do
          expect(subject.value).to eq(pea)
        end
      end # context

      context 'Provided services:' do
        let(:ctx) { Context.new }

        it 'should tell whether the associated value is pinned' do
          ctx.add_vars(%w[q x])

          expect(subject).to be_pinned(ctx)
          instance = Association.new(ctx.lookup('q'), LogVarRef.new('x'))
          expect(instance).not_to be_pinned(ctx)
        end

        it 'should tell whether the associated value is floating' do
          ctx.add_vars(%w[q x])

          expect(subject).not_to be_floating(ctx)
        end

        it 'should retrieve the dependencies in its value' do
          expect(subject.dependencies(ctx)).to be_empty

          ctx.add_vars(%w[q x])
          instance = Association.new(ctx.lookup('q'), LogVarRef.new('x'))
          expect(instance.dependencies(ctx).size).to eq(1)
        end
      end # context
    end # describe
  end # module
end # module
