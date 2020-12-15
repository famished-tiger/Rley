# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

require_relative '../../lib/mini_kraken/core/all_core'

module MiniKraken
  module Core
    # Integration-in-the-small testing
    describe 'Core Classes' do
      let(:ctx) { Context.new }

      context 'Executing nullary goals:' do
        def var(aName)
          LogVar.new(aName)
        end

        it 'should execute nullary fail goal' do
          # Equivalent to frame 1:7
          goal = Goal.new(Fail.instance, [])
          ctx.insert(var('q'))
          result = goal.achieve(ctx)
          expect(result.resume).to eq(ctx)
          expect(ctx).to be_failure
          expect(ctx.associations_for('q')).to be_empty
        end

        it 'should execute nullary succeed goal' do
          # Equivalent to frame 1:17
          goal = Goal.new(Succeed.instance, [])
          ctx.insert(var('q'))
          result = goal.achieve(ctx)
          expect(result.resume).to eq(ctx)
          expect(ctx).to be_success
          expect(ctx.associations_for('q')).to be_empty # RS: (_0)
        end
      end # context
    end # describe
  end # module
end # module
