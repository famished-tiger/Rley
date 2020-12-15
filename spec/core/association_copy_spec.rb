# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/context'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'

# Load the class under test
require_relative '../../lib/mini_kraken/core/association_copy'

module MiniKraken
  module Core
    describe AssociationCopy do
      include MiniKraken::FactoryAtomic # Use mix-in module

      let(:pea) { k_symbol(:pea) }
      let(:q_assoc) { Association.new('q', pea) }      
      subject { AssociationCopy.new('q_x', q_assoc) }

      context 'Initialization:' do
        it 'should be initialized with a name and an association' do
          expect { AssociationCopy.new('q_x', q_assoc) }.not_to raise_error
        end

        it 'should be initialized with a variable and an association' do
          q_x_var = LogVar.new('q_x')
          expect { AssociationCopy.new(q_x_var, q_assoc) }.not_to raise_error
        end

        it 'should know the internal variable name' do
          expect(subject.i_name).to eq('q_x')
        end

        it 'should know the associated value' do
          expect(subject.value).to eq(pea)
        end
      end # context

      context 'Provided services:' do
        let(:ctx) { Context.new }

        it 'should tell whether the associated value is pinned' do
          ctx.add_vars(['q', 'x', 'q_x'])
          expect(subject).to be_pinned(ctx)
          
          a = Association.new(ctx.lookup('q'), LogVarRef.new('x'))          
          instance = AssociationCopy.new(ctx.lookup('q_x'), a)
          expect(instance).not_to be_pinned(ctx)
        end

        it 'should tell whether the associated value is floating' do
          ctx.add_vars(['q', 'x', 'q_x'])

          expect(subject).not_to be_floating(ctx)
        end
        
        it 'should retrieve the dependencies in its value' do
          expect(subject.dependencies(ctx)).to be_empty

          ctx.add_vars(['q', 'x', 'q_x'])          
          a = Association.new(ctx.lookup('q'), LogVarRef.new('x'))
          instance = AssociationCopy.new(ctx.lookup('q_x'), a)          
          expect(instance.dependencies(ctx).size).to eq(1)
        end
      end # context
    end # describe
  end # module
end # module
