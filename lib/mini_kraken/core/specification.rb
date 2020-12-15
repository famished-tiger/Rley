# frozen_string_literal: true

require_relative 'arity'

module MiniKraken
  module Core
    class Specification
      # @return [String] Name of the specification object.
      attr_reader :name
      
      # @return [Arity] arity = allowed number of arguments
      attr_reader :arity

      # @param aName [String] Name of the relation.
      # @param anArity [Arity, Integer] Arity of the relation.
      def initialize(aName, anArity)
        @name = aName
        @arity = anArity.is_a?(Integer) ? Arity.new(anArity, anArity) : anArity
      end

      # A relation is variadic when it accepts an arbitrary number of arguments.
      # Most built-in relation takes a fixed number of arguments (= arity).
      # @return [Boolean]
      def variadic?
        arity.variadic?
      end

      def inspect
        name + "[#{arity.low}]"
      end
      
      # Control that the number of actual arguments matches
      # the relation's arity.
      # Raise an exception if the check fails
      # @param actuals [Array<Term>] Actuals from a goal.
      # @return [Array<Term>] Input array if compatible with arity.
      def check_arity(actuals)
        unless arity.match?(actuals.size)
          msg1 = "Count of arguments (#{actuals.size})"
          msg2 = " is out of allowed range (#{arity.low}, #{arity.high})."
          raise StandardError, msg1 + msg2
        end
        
        actuals
      end
    end # class
  end # module
end # module
