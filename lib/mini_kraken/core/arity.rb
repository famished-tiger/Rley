# frozen_string_literal: true

module MiniKraken
  module Core
    # The arity is the number of arguments a relations or a function can take.
    Arity = Struct.new(:low, :high) do
      # Is the arity constrained to a single, unique value?
      # In other words, are the low and high bound equal?
      # @return [Boolean] true iff both bounds have same value
      def unique?
        low == high
      end

      # Is the arity set to zero?
      # @return [Boolean] true if arity is exactly zero
      def nullary?
        unique? && low.zero?
      end

      # Is the arity set to one?
      # @return [Boolean] true if arity is exactly one
      def unary?
        unique? && low == 1
      end

      # Is the arity set to two?
      # @return [Boolean] true if arity is exactly two
      def binary?
        unique? && low == 2
      end

      # Can the arity take arbitrary values?
      # @return [Boolean] true if arity has no fixed high bound
      def variadic?
        high == '*'
      end

      # Does the given argument value fits within the boundary values?
      # @param aCount [Integer]
      # @return [Boolean]
      def match?(aCount)
        is_matching = aCount >= low
        is_matching &&= aCount <= high unless variadic?

        is_matching
      end

      # Equality check
      # @param other [Arity, Array, Integer]
      # @return [Boolean] true if 'other' has same boundary values.
      def ==(other)
        return true if object_id == other.object_id

        result = false

        case other
          when Arity
            result = true if (low == other.low) && (high == other.high)
          when Array
            result = true if (low == other.first) && (high == other.last)
          when Integer
            result = true if (low == other) && (high == other)
        end

        result
      end
    end # struct
  end # module
end # module
