# frozen_string_literal: true

require 'set'

require_relative '../core/all_core'
require_relative '../atomic/all_atomic'
require_relative '../composite/cons_cell'
require_relative '../rela/all_rela'
require_relative 'run_star_expression'

module MiniKraken
  module Glue
    # The mixin module that implements the methods for the DSL
    # (DSL = Domain Specific Langague) that allows MiniKraken
    # users to embed Minikanren in their Ruby code.
    module DSL
      # A run* expression tries to find all the solutions
      # that meet the given goal.
      # @return [Composite::ConsCell] A list of solutions
      def run_star(var_names, goal)
        program = RunStarExpression.new(var_names, goal)
        program.run
      end

      def conde(*goals)
        args = goals.map do |goal_maybe|
          if goal_maybe.kind_of?(Array)
            goal_maybe.map { |g| convert(g) }
          else
            convert(goal_maybe)
          end
        end

        Core::Goal.new(Rela::Conde.instance, args)
      end

      # conj2 stands for conjunction of two arguments.
      # Returns a goal linked to the Core::Conj2 relation.
      # The rule of that relation succeeds when both arguments succeed.
      # @param arg1 [Core::Goal]
      # @param arg2 [Core::Goal]
      # @return [Core::Failure|Core::Success]
      def conj2(arg1, arg2)
       goal_class.new(Rela::Conj2.instance, [convert(arg1), convert(arg2)])
      end

      def cons(car_item, cdr_item = nil)
        tail = cdr_item.nil? ? cdr_item : convert(cdr_item)
        Composite::ConsCell.new(convert(car_item), tail)
      end

      def null_list
        Composite::ConsCell.new(nil, nil)
      end

      def defrel(relationName, theFormals, aGoalExpr)
        case theFormals
          when String
            formals = [theFormals]
          when Array
            formals = theFormals
        end      
        rela = Rela::DefRelation.new(relationName, aGoalExpr, formals)
        add_defrel(rela)
        
       # start_defrel

        # formals = @defrel_formals.map { |name| Core::FormalArg.new(name) }
        # g_template = aGoalTemplateExpr.call
        # result = Core::DefRelation.new(relationName, g_template, formals)
        # add_defrel(result)

        # end_defrel
        # result
      end

      def disj2(arg1, arg2)
        goal_class.new(Rela::Disj2.instance, [convert(arg1), convert(arg2)])
      end

      # @return [Core::Fail] A goal that unconditionally fails.
      def _fail
        goal_class.new(Core::Fail.instance, [])
      end

      def unify(arg1, arg2)
        goal_class.new(Rela::Unify.instance, [convert(arg1), convert(arg2)])
      end

      # @return [Core::Goal]
      def fresh(names, subgoal)
        # puts "#{__callee__} #{names}"
        Rela::Fresh.build_goal(names, subgoal)
      end

      def list(*members)
        return null if members.empty?
        converted = members.map { |e| convert(e) }
        Composite::List.make_list(converted)
      end

      # @return [ConsCell] Returns an empty list, that is, a pair whose members are nil.
      def null
        Composite::ConsCell.null
      end

      # @return [Core::Succeed] A goal that unconditionally succeeds.
      def succeed
        goal_class.new(Core::Succeed.instance, [])
      end

      private

      def convert(anArgument)
        converted = nil

        case anArgument
          when Symbol
            if anArgument.id2name =~ /_\d+/
              rank = anArgument.id2name.slice(1..-1).to_i
              any_val = Core::AnyValue.allocate
              any_val.instance_variable_set(:@rank, rank)
              converted = any_val
            elsif anArgument.id2name =~ /^"#[ft]"$/
              converted = Atomic::KBoolean.new(anArgument)
            else
              converted = Atomic::KSymbol.new(anArgument)
            end
          when String
            if anArgument =~ /^#[ft]$/
              converted = Atomic::KBoolean.new(anArgument)
            else
              msg = "Internal error: undefined conversion for #{anArgument.class}"
              raise StandardError, msg
            end
          when false, true
            converted = Atomic::KBoolean.new(anArgument)
          when Atomic::KBoolean, Atomic::KSymbol
            converted = anArgument
          when Core::Goal
            converted = anArgument
          when Core::LogVarRef
            converted = anArgument
          when Composite::ConsCell
            converted = anArgument
          when NilClass
            converted = anArgument
          else
            msg = "Internal error: undefined conversion for #{anArgument.class}"
            raise StandardError, msg
        end

        converted
      end

      def default_mode
        @dsl_mode = :default
        @defrel_formals = nil
      end

      def goal_class
        default_mode unless instance_variable_defined?(:@dsl_mode)
        @dsl_mode == :default ? Core::Goal : Core::GoalTemplate
      end

      def start_defrel
        @dsl_mode = :defrel
        @defrel_formals = Set.new
      end

      def end_defrel
        default_mode
      end

      def add_defrel(aDefRelation)
        @defrels ||= {}
        @defrels[aDefRelation.name] = aDefRelation
      end

      def method_missing(mth, *args)
        result = nil

        begin
          result = super(mth, *args)
        rescue NameError
          name = mth.id2name
          @defrels ||= {}
          if @defrels.include?(name)
            def_relation = @defrels[name]
            result = Core::Goal.new(def_relation, args.map { |el| convert(el) })
          else
            default_mode unless instance_variable_defined?(:@dsl_mode)
            if @dsl_mode == :defrel && @defrel_formals.include?(name)
              result = Core::FormalRef.new(name)
            else
              result = Core::LogVarRef.new(name)
            end
          end
        end

        result
      end
    end # module
  end # module
end # module
