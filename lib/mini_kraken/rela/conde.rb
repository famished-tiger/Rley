# frozen_string_literal: true

require 'singleton'
require_relative '../core/context'
require_relative '../core/duck_fiber'
require_relative '../core/fail'
require_relative '../core/goal'
require_relative 'conj2'

require_relative 'goal_relation'

module MiniKraken
  module Rela
    # A polyadic relation (i.e. it can takes an arbitrary number of argumentt)
    # that behaves as the disjunction of its arguments.
    # It succeeds if at least one of its goal arguments succeeds.
    class Conde < GoalRelation
      include Singleton

      def initialize
        super('conde', Core::Arity.new(1, '*'))
      end

      # A relation is polyadic when it accepts an arbitrary number of arguments.
      # @return [TrueClass]
      def polyadic?
        true
      end

      # @param actuals [Array<Term>] A two-elements array
      # @param ctx [Core::Context] A vocabulary object
      # @return [Fiber<Context>] A Fiber that yields Outcomes objects
      def solver_for(actuals, ctx)
        args = *validated_args(actuals)
        Fiber.new { cond(args, ctx) }
      end

      # Yields [Context, NilClass] result of the disjunction
      # @param goals [Array<Goal>] Array of goals
      # @param ctx [Context] A ctxabulary object
      def cond(goals, ctx)
        # require 'debug'
        success = false
        ctx.place_bt_point

        goals.each do |g|
          fiber = nil

          case g
            when Core::Goal
              fiber = g.achieve(ctx)
            when Array
              conjunct = conjunction(g)
              fiber = conjunct.achieve(ctx)
            # when Core::ConsCell
              # goal_array = to_goal_array(g)
              # conjunct = conjunction(goal_array)
              # fiber = conjunct.achieve(ctx)
            else
              raise NotImplementedError
          end

          loop do
            outcome = fiber.resume(ctx)
            break if outcome.nil?

            if outcome.success?
              success = true
              Fiber.yield outcome
            end
          end

          ctx.next_alternative
        end

        Fiber.yield ctx.failed! unless success
        ctx.retract_bt_point
        Fiber.yield nil
      end

      private

      def validated_args(actuals)
        result = []

        actuals.each do |arg|
          case arg
            when Core::Goal
              result << arg

            when Core::Context
              result << arg

            when Array
              result << validated_args(arg)

            else
              prefix = "#{name} expects goal as argument, found a "
              raise StandardError, prefix + "'#{arg.class}'"
          end
        end

        result
      end

      # Given an array of goals, build the conjunction of these.
      def conjunction(goal_array)
        result = nil

        loop do
          conjunctions = []
          goal_array.each_slice(2) do |uno_duo|
            if uno_duo.size == 2
              conjunctions << Core::Goal.new(Rela::Conj2.instance, uno_duo)
            else
              conjunctions << uno_duo[0]
            end
          end
          if conjunctions.size == 1
            result = conjunctions[0]
            break
          end
          goal_array = conjunctions
        end

        result
      end

      def to_goal_array(aCons)
        array = []
        curr_node = aCons
        loop do
          array << curr_node.car if curr_node.car.kind_of?(Core::Goal)
          break unless curr_node.cdr
          break unless curr_node.car.kind_of?(Core::Goal)

          curr_node = curr_node.cdr
        end

        array
      end
    end # class

    Conde.instance.freeze
  end # module
end # module

