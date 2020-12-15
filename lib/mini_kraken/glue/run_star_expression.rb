# frozen_string_literal: true

require_relative '../core/context'
require_relative '../composite/list'
require_relative '../rela/fresh'

module MiniKraken
  module Glue
    class RunStarExpression
      # @return [Core::Context] The context in which run* variables 
      #   will be evaluated.
      attr_reader :ctx
      
      # @return [Core::Goal] The main goal to satisfy
      attr_reader :goal

      # @param var_names [String, Array<String>] One variable name or an array of names
      # @param aGoal [Core::Goal, Array<Core::Goal>] A single goal or an array of goals to conjunct
      def initialize(var_names, aGoal)
        @ctx = Core::Context.new
        ctx.add_vars(var_names)
        @goal = Rela::Fresh.compose_goals(aGoal)        
      end

      # Run the query, that is, try to find ALL solutions
      # of the provided qoal.
      # One solution corresponds to allowed value associated
      # to the provided logical variable(s).
      #
      def run
        result = []
        solver = goal.achieve(ctx) # A solver == Fiber(-like) yielding Context
        # require 'debug'        

        loop do        
          outcome = solver.resume(ctx)
          break if outcome.nil? # No other solution?

          result << outcome.build_solution.values if outcome.success?
        end

        format_solutions(result)
      end

      private

      # Transform the solutions into sequence of conscells.
      # @param solutions [Array<Array>] An array of solution.
      # A solution is in itself an array of bindings (one per variable)
      def format_solutions(solutions)
        solutions_as_list = solutions.map { |sol| arr2list(sol, true) }
        arr2list(solutions_as_list, false)
      end

      # Utility method. Transform an array into a ConsCell-based list.
      # @param anArray [Array]
      # @param simplify [Boolean]
      def arr2list(anArray, simplify)
        if anArray.size == 1 && simplify
          anArray[0] 
        else
          Composite::List.make_list(anArray)
        end
      end
    end # class
  end # module
end # module