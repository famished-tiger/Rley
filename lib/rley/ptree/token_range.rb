module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
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
