# frozen_string_literal: true

require 'singleton'
require_relative '../core/solver_adapter'
require_relative '../atomic/k_string'
require_relative 'conj2'
require_relative 'goal_relation'

module MiniKraken
  module Rela
    # A specialized relation that accepts a variable names(s) and a subgoal
    # as its arguments.
    class Fresh < GoalRelation
      include Singleton
      # Default initialization
      def initialize
        super('fresh', 2)
      end

      def self.build_goal(names, subgoals)
        var_names = nil

        case names
          when String
            var_names = Atomic::KString.new(names)

          when Array
            var_names = names.map do |nm|
              nm.is_a?(String) ? Atomic::KString.new(nm) : nm
            end
        end

        nested_goal = compose_goals(subgoals)
        Core::Goal.new(instance, [var_names, nested_goal])
      end

      def self.compose_goals(subgoals)
        nested_goal = nil

        case subgoals
          when Core::Goal
            nested_goal = subgoals

          when Array
            goal_array = subgoals
            loop do
              conjunctions = []
              goal_array.each_slice(2) do |uno_duo|
                if uno_duo.size == 2
                  conjunctions << Core::Goal.new(Conj2.instance, uno_duo)
                else
                  conjunctions << uno_duo[0]
                end
              end
              if conjunctions.size == 1
                nested_goal = conjunctions[0]
                break
              end
              goal_array = conjunctions
            end
          end

        nested_goal
      end

      # @param actuals [Array<Array<KString>, Core::Term>] A two-elements array
      # First element is an array of variable names to create.
      # Second is a sub-goal object
      # @param ctx [Core::Context] A context object
      # @return [Fiber<Core::Context>] A Fiber that yields Context objects
      def solver_for(actuals, ctx)
        k_names = actuals.shift
        # require 'debug'
        subgoal = validated_args(actuals).first

        ctx.enter_scope(Core::Scope.new)
        if k_names.kind_of?(Atomic::KString)
          ctx.add_vars(k_names.value)
        else
          # ... Array of KString
          names = k_names.map(&:value)
          ctx.add_vars(names)
        end

        # Wrap the subgoal's solver by an adapter
        orig_solver = subgoal.achieve(ctx)
        Core::SolverAdapter.new(orig_solver) do |adp, context|
          # puts "Adaptee #{adp.adaptee}"
          result = adp.adaptee.resume(context)
          context.leave_scope if result.nil?
          result
        end
      end
    end # class

    Fresh.instance.freeze
  end # module
end # module
