# frozen_string_literal: true

require_relative '../core/term'
# require_relative '../core/freshness'

module MiniKraken
  # This module packages the atomic term classes, that is,
  # the basic datatypes that cannot be decomposed
  # in MiniKraken into simpler, smaller data values.
  module Atomic
    # An atomic term is an elementary MiniKraken term, a data value
    # that cannot be decomposed into simpler MiniKraken term(s).
    # Typically, an atomic term encapsulates a Ruby primitive data object.
    # MiniKraken treats atomic terms as immutable objects.
    class AtomicTerm < Core::Term
      # @return [Object] Internal representation of a MiniKraken data value.
      attr_reader :value

      # Initialize an atomic term with the given data object.
      # @param aValue [Object] Ruby representation of MiniKraken data value
      def initialize(aValue)
        super()
        @value = aValue
        @value.freeze
      end

      # An atomic term, by definition is bound to a definite value.
      # @param _ctx [Context]
      # @return [FalseClass]
      def unbound?(_ctx)
        false
      end

      # An atomic term has a definite value, therefore it is not floating.
      # @param _ctx [Context]
      # @return [FalseClass]
      def floating?(_ctx)
        false
      end

      # An atomic term is a pinned term: by definition, it has a definite
      # value.
      # @param _ctx [Context]
      # @return [TrueClass]
      def pinned?(_ctx)
        true
      end

      # Return a String representation of the atomic term
      # @return [String]
      def to_s
        value.to_s
      end

      # Treat this object as a data value.
      # @return [AtomicTerm]
      def quote(_ctx)
        self
      end

      # Data equality testing
      # @param other [AtomicTerm, #value]
      # @return [Boolean]
      def ==(other)
        if other.respond_to?(:value)
          value == other.value
        else
          value == other
        end
      end

      # Type and data equality testing
      # @param other [AtomicTerm]
      # @return [Boolean]
      def eql?(other)
        (self.class == other.class) && value.eql?(other.value)
      end

      # Return the list of variable (i_names) that this term depends on.
      # For atomic terms, there is no such dependencies.
      # @param _ctx [Core::Context]
      # @return [Set] an empty set
      def dependencies(_ctx)
        Set.new
      end

      # Make a copy of self with all the variable reference being
      # replaced by the corresponding value in the Hash.
      # @param _substitutions [Hash {String => Term}]
      # @return [Term]
      def dup_cond(_substitutions)
        self.dup
      end
    end # class
  end # module
end # module
