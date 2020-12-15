# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/context'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/atomic/k_symbol'
require_relative '../../lib/mini_kraken/composite/cons_cell'

# Load the class under test
require_relative '../../lib/mini_kraken/core/log_var_ref'


module MiniKraken
  module Core
    describe LogVarRef do
      let(:ctx) { Context.new }
      let(:foo) { Atomic::KSymbol.new(:foo) }
      subject { LogVarRef.new('q') }

      context 'Initialization:' do
        it 'should be initialized with a name' do
          expect { LogVarRef.new('q') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('q')
        end

        it 'should not know the internal name of the variable' do
          expect(subject.i_name).to be_nil
        end
      end # context

      context 'Provided services:' do
        def var(aName)
          LogVar.new(aName)
        end

        it 'should know whether its variable is unbound or not' do
          v = var('q')
          ctx.insert(v)
          expect(subject).to be_unbound(ctx)
          ctx.associate('q', double('something'))
          expect(subject).not_to be_unbound(ctx)
        end

        it 'should know whether its variable is floating or not' do
          ctx.add_vars(%w[q x])
          expect(subject).not_to be_floating(ctx)

          x_ref = LogVarRef.new('x')
          ctx.associate('q', x_ref)
          expect(subject).to be_floating(ctx)
        end

        it 'should know whether its variable is pinned or not' do
          ctx.add_vars(%w[q x])
          expect(subject).not_to be_pinned(ctx)

          x_ref = LogVarRef.new('x')
          ctx.associate('q', x_ref)
          expect(subject).not_to be_pinned(ctx)

          ctx.associate('x', foo)
          expect(subject).to be_pinned(ctx)
        end

        it 'should return its variable as its sole dependency' do
          ctx.add_vars('q')

          expect(subject.i_name).to be_nil
          expect(subject.dependencies(ctx).size).to eq(1)
          v = ctx.lookup(subject.name)
          expect(subject.i_name).to eq(v.i_name)
          expect(subject.dependencies(ctx).to_a).to eq([v.i_name])
        end

        it 'should duplicate itself when its variable has no value' do
          substitutions = { 'z' => foo }

          result = subject.dup_cond(substitutions)
          expect(result).to be_kind_of(LogVarRef)
          expect(result.name).to eq(subject.name)
        end

        it 'should replace itself when its variable has an atomic value' do
          substitutions = { 'q' => foo }

          result = subject.dup_cond(substitutions)
          expect(result).to eq(:foo)
        end

        it 'should replace itself when its variable has an atomic value' do
          x_ref = LogVarRef.new('x')
          substitutions = { 'q' => x_ref, 'x' => foo }

          # The substitutions are chained
          result = subject.dup_cond(substitutions)
          expect(result).to be_kind_of(Atomic::KSymbol)
          expect(result).to eq(:foo)
        end
      end # context
    end # describe
  end # module
end # module
