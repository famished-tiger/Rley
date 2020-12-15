# frozen_string_literal: true

module MiniKraken
  module Core
    # When MiniKraken successfully finds a solution but cannot associate
    # a definite value to one or more logical variable(s), then it is
    # useful to "assign" such unbound variable a placeholder that stands
    # for any possible value. Following the practice of the "Reasoned Scheme"
    # book, we associate a rank number to such a placeholder in order
    # to distinguish arbitrary values from independent variables.
    class AnyValue
      # The rank number helps to differentiate independent variables.
      # @return [Integer]
      attr_reader :rank

      # @param aRank [Integer] The rank of the variable that must reified.
      def initialize(aRank)
        @rank = aRank
      end

      # Compare with another instance.
      # @param other [AnyValue, Integer, Symbol]
      # @return [Boolean]
      def ==(other)
        if other.is_a?(AnyValue)
          rank == other.rank
        elsif other.is_a?(Integer)
          rank == other
        elsif other.id2name =~ /_\d+/
          rank == other.id2name.sub(/_/, '').to_i
        end
      end

      # Use same text representation as in "Reasoned Schemer" book.
      # return [String]
      def to_s
        "_#{rank}"
      end

      def pinned?(_ctx)
        false
      end

      # @return [AnyValue]
      def quote(_ctx)
        self
      end

      private

      def valid_rank(aRank)
        unless aRank.kind_of?(Integer)
          msg = "Rank number MUST be an Integer, found a #{aRank.class}"
        end

        aRank
      end
    end # class
  end # module
end # module
