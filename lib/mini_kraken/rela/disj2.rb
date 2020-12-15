# frozen_string_literal: true

require 'singleton'

require_relative '../core/context'
require_relative '../core/duck_fiber'
require_relative 'goal_relation'

module MiniKraken
  module Rela
    # The disjunction is a relation that accepts only goal(s) as its two
    # arguments. It succeeds if at least one of its goal arguments succeeds.
    class Disj2 < GoalRelation
      include Singleton

      # Default initialization
      def initialize
        super('disj2', 2)
      end

      # @param actuals [Array<Core::Term>] A two-elements array
      # @param ctx [Core::Context] A context object
      # @return [Fiber<Core::Context>] A Fiber that yields Context objects
      def solver_for(actuals, ctx)
        g1, g2 = *validated_args(actuals)
        Fiber.new { disjunction(g1, g2, ctx) }
      end

      # Yields [Core::Context, NilClass] result of the disjunction
      # @param g1 [Goal] First goal argument
      # @param g2 [Goal] Second goal argument
      # @param ctx [Core::Context] A ctxabulary object
      def disjunction(g1, g2, ctx)
        # require 'debug'
        if g1.relation.kind_of?(Core::Fail) && g2.relation.kind_of?(Core::Fail)
          Fiber.yield ctx.failed!
        else
          ctx.place_bt_point
          outcome1 = nil
          outcome2 = nil
          f1 = g1.achieve(ctx)
          loop do
            outcome1 = f1.resume(ctx)
            break if outcome1.nil?

            if outcome1.success?
              Fiber.yield outcome1
              ctx.next_alternative
            end
          end
          f2 = g2.achieve(ctx)
          loop do
            outcome2 = f2.resume(ctx)
            break if outcome2.nil?

            if outcome2.success?
              Fiber.yield outcome2
              ctx.next_alternative
            end
          end
        end

        ctx.retract_bt_point
        Fiber.yield nil
      end
    end # class

    Disj2.instance.freeze
  end # module
end # module
