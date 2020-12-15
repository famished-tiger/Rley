# frozen_string_literal: true

require 'singleton'

require_relative '../core/context'
require_relative '../core/duck_fiber'
require_relative 'goal_relation'

module MiniKraken
  module Rela
    # The conjunction is a relation that accepts only two goals as its
    # arguments. It succeeds if and only if both its goal arguments succeeds.
    class Conj2 < GoalRelation
      include Singleton

      # Default initialization
      def initialize
        super('conj2', 2)
      end

      # @param actuals [Array<Core::Term>] A two-elements array
      # @param ctx [Core::Context] A context object
      # @return [Fiber<Core::Context>] A Fiber that yields Context objects
      def solver_for(actuals, ctx)
        g1, g2 = *validated_args(actuals)
        Fiber.new { conjunction(g1, g2, ctx) }
      end

      # Yields [Core::Context, NilClass] result of the conjunction
      # @param g1 [Goal] First goal argument
      # @param g2 [Goal] Second goal argument
      # @param ctx [Core::Context] A ctxabulary object
      def conjunction(g1, g2, ctx)
        # require 'debug'
        if g1.relation.kind_of?(Core::Fail) || g2.relation.kind_of?(Core::Fail)
          Fiber.yield ctx.failed!
        else  
          outcome1 = outcome2 = nil
          fiber1 = g1.achieve(ctx)

          loop do
            outcome1 = fiber1.resume(ctx)
            break if outcome1.nil?

            if outcome1.success?
              fiber2 = g2.achieve(ctx)
              loop do
                outcome2 = fiber2.resume(ctx)
                break if outcome2.nil?

                Fiber.yield outcome2
              end
            else
              Fiber.yield outcome1
            end
          end
        end

        Fiber.yield nil
      end
    end # class

    Conj2.instance.freeze
  end # module
end # module
