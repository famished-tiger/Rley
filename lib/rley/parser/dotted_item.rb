module Rley # This module is used as a namespace
  # A dotted item is a parse state for a given production/grammar rule
  # It partitions the rhs of the rule in two parts.
  # The left part consists of the symbols in the rules that are matched
  # by the input tokens.
  # The right part consists of symbols that are predicted to match the
  # input tokens.
  # The terminology stems from the traditional way to visualize the partition
  # by using a fat dot character as a separator between the left and right
  # parts
  # An item with the dot at the beginning (i.e. before any rhs symbol)
  #  is called a predicted item.
  # An item with the dot at the end (i.e. after all rhs symbols)
  #  is called a reduce item.
  # An item with a dot in front of a terminal is called a shift item.
  module Parser # This module is used as a namespace
    class DottedItem
      # Production rule
      attr_reader(:production)

      # Index of the next symbol (from the rhs) after the 'dot'.
      # If the dot is at the end of the rhs (i.e.) there is no next
      # symbol, then the position takes the value -1.
      # It the rhs is empty, then the position is -2
      attr_reader(:position)

      # @param aProduction
      def initialize(aProduction, aPosition)
        @production = aProduction
        @position = valid_position(aPosition)
      end

      # Return a String representation of the dotted item.
      # @return [String]
      def to_s()
        prefix = "#{production.lhs} => "
        text_values = production.rhs.map(&:to_s)
        if position < 0
          text_values << '.'
        else
          text_values.insert(position, '.')
        end
        suffix = text_values.join(' ')

        return prefix + suffix
      end

      # Return true if the dot position is at the start of the rhs.
      def at_start?()
        return position.zero? || position == -2
      end

      # An item with the dot at the beginning is called
      # predicted item
      alias predicted_item? at_start?

      # A dotted item is called a reduce item if the dot is at the end.
      def reduce_item?()
        return position < 0 # Either -1 or -2
      end

      # The non-terminal symbol that is on the left-side of the production
      def lhs()
        return production.lhs
      end

      # Return the symbol before the dot.
      # nil is returned if the dot is at the start of the rhs
      def prev_symbol()
        before_position = prev_position
        result = if before_position.nil?
                   nil
                 else
                   production.rhs[before_position]
                 end

        return result
      end

      # Return the symbol after the dot.
      # nil is returned if the dot is at the end
      def next_symbol()
        return position < 0 ? nil : production.rhs[position]
      end

      # Calculate the position of the dot if were moved by
      # one step on the left.
      def prev_position()
        case position
          when -2, 0
            result = nil
          when -1
            result = production.rhs.size == 1 ? 0 : production.rhs.size - 1
          else
            result = position - 1
        end

        return result
      end

      # An item with the dot in front of a terminal is called a shift item
      def shift_item?()
        return position.zero?
      end

      # Return true if this dotted item has a dot one place
      # to the right compared to the dotted item argument.
      def successor_of?(another)
        return false if production != another.production
        to_the_left = prev_position
        return false if to_the_left.nil?
        return to_the_left == another.position
      end


      private

      # Return the given position after its validation.
      def valid_position(aPosition)
        rhs_size = production.rhs.size
        if aPosition < 0 || aPosition > rhs_size
          raise StandardError, 'Out of bound index'
        end

        index = if rhs_size.zero?
                  -2 # Minus 2 at start/end of empty production
                elsif aPosition == rhs_size
                  -1 # Minus 1 at end of non-empty production
                else
                  aPosition
                end

        return index
      end
    end # class
  end # module
end # module

# End of file
