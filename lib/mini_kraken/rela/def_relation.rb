# frozen_string_literal: true

require 'securerandom'
require_relative '../core/relation'
require_relative '../core/entry'

module MiniKraken
  module Rela
    # A user-defined relation with:
    # - a user-defined name,
    # - a ordered list of generic formal arguments, and;
    # - a goal template expression.
    class DefRelation < Core::Relation
      include Core::Entry # Add behaviour of symbol table entries

      # @return [Array<FormalArg>] formal arguments of this DefRelation
      attr_reader :formals

      # @return [Term] Expression to be fulfilled and parametrized with formals
      attr_reader :expression

      # @param aName [String] name of def relation
      # @param anExpression [Term]
      # @param theFormals [Array<String>]
      def initialize(aName, anExpression, theFormals)
        @formals = validated_formals(theFormals)
        formal_vars = formals.map { |nm| Core::LogVarRef.new(nm) }
        raw_expression = validated_expression(anExpression)
        @expression = replace_expression(raw_expression, theFormals, formal_vars)
        super(aName, formals.size)
        freeze
      end

      # @param actuals [Array<Term>] A two-elements array
      # @param ctx [Context] A Context object
      # @return [Fiber<Outcome>] A Fiber(-like) instance that yields Outcomes
      def solver_for(actuals, ctx)
        actual_expr = replace_expression(expression, formals, actuals)
        actual_expr.achieve(ctx)
      end

      private

      def validated_formals(theFormals)
        # Make the formal names unique, to avoid name collision
        theFormals.map { |name| "#{name}_#{SecureRandom.uuid}" }
      end

      def validated_expression(aGoalTemplate)
        raise StandardError unless aGoalTemplate

        aGoalTemplate
      end

      # With the given expression, create a new expression where
      # each allusion to original variable is replaced by the
      # by its corresponding actual value.
      def replace_expression(anExpression, original, actual)
        raw_pairs = original.zip(actual) # [original, actual]
        anExpression.dup_cond(raw_pairs.to_h)
      end
    end # class
  end # module
end # module
