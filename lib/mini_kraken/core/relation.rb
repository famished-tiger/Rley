# frozen_string_literal: true

require_relative 'specification'
require_relative 'context'

module MiniKraken
  module Core
    # Formally, a n-relation over R, where R represents the cartesian product
    # (A1 x A2 x ... An) is a subset of R.
    # In other words, a n-relation is a subset of all tuples represented by R.
    # In MiniKraken, a n-relation is an object that indicates whether a given
    # tuple -of length n- is valid (or non valid).
    class Relation < Specification
      # Contructor
      # @param aName [String] Name of the relation.
      # @param anArity [Arity, Integer] Arity of the relation.
      def initialize(aName, anArity)
        super(aName, anArity)
      end
      
      # Abstract method to override in subclass(es).
      # @param actuals [Array<Term>] Argument count must 
      # @param ctx [Core::Context] Runtime context
      # @return [#resume] A Fiber-like object that yields Context.
      def solver_for(actuals, ctx)
        raise NotImplementedError
      end
    end # class
  end # module
end # module
