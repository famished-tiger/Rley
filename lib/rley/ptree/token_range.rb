module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    # A token range (also called an extent) represents an interval 
    # of token positions that is matched by a given grammar symbol.
    # For instance consider the expression E: 3 + 11,
    # let's assume that the integer literal '3' is the fifth input token and
    # that the '+' and '11' tokens are respectively at position 6 and 7;
    # then the token range associated with E is [5, 7]
    # While the parse tree/forest is being constructed the boundaries of the 
    # token range can be temporarily undefined (= set to nil)
    class TokenRange
      # The index of the lower bound of token range
      attr_reader(:low)

      # The index of the upper bound of token range
      attr_reader(:high)

      # @param aRangeRep [Hash]
      def initialize(aRangeRep)
        assign_low(aRangeRep)
        assign_high(aRangeRep)
      end


      def ==(other)
        return true if object_id == other.object_id

        case other
          when Hash
            result = low == other[:low] && high == other[:high]
          when TokenRange
            result = low == other.low && high == other.high
          when Array
            result = low == other[0] && high == other[1]
        end

        return result
      end

      # true when both bounds aren't nil.
      def bounded?()
        return !(low.nil? || high.nil?)
      end

      # Conditional assign
      def assign(aRange)
        return if bounded?

        assign_low(aRange) if low.nil?
        assign_high(aRange) if high.nil?
      end

      # Tell whether the given index value lies outside the range
      def out_of_range?(index)
        result = false
        result = true if !low.nil? && index < low
        result = true if !high.nil? && index > high

        return result
      end

      # Emit a (formatted) string representation of the range.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(_indentation)
        low_text = low.nil? ? '?' : low.to_s
        high_text = high.nil? ? '?' : high.to_s
        
        return "[#{low_text}, #{high_text}]"
      end

      private

      def assign_low(aRange)
        case aRange
          when Hash then @low = aRange.fetch(:low, nil)
          when TokenRange then @low = aRange.low
        end
      end

      def assign_high(aRange)
        case aRange
          when Hash then @high = aRange.fetch(:high, nil)
          when TokenRange then @high = aRange.high
        end
      end
    end # class
  end # module
end # module
# End of file
