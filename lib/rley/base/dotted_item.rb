# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Base # This module is used as a namespace
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
    class DottedItem
      # Production rule
      # @return [Syntax::Production]
      attr_reader :production

      # Index of the next symbol (from the rhs) after the 'dot'.
      # If the dot is at the end of the rhs (i.e.) there is no next
      # symbol, then the position takes the value -1.
      # It the rhs is empty, then the position is -2
      # @return [Integer]
      attr_reader :position

      # A possible constraint between symbol on left of dot and
      # the closest preceding given terminal
      # @return [NilClass, Syntax::MatchClosest]
      attr_accessor :constraint

      # @param aProduction [Syntax::Production]
      # @param aPosition [Integer] Position of the dot in rhs of production.
      def initialize(aProduction, aPosition)
        @production = aProduction
        @position = valid_position(aPosition)
      end

      # Return a String representation of the dotted item.
      # @return [String]
      def to_s
        prefix = "#{production.lhs} => "
        text_values = production.rhs.map(&:to_s)
        if position.negative?
          text_values << '.'
        else
          text_values.insert(position, '.')
        end
        suffix = text_values.join(' ')

        prefix + suffix
      end

      # Return true if the dot position is at the start of the rhs.
      # @return [Boolean]
      def at_start?
        position.zero? || position == -2
      end

      # An item with the dot at the beginning is called
      # predicted item
      alias predicted_item? at_start?

      # A dotted item is called a reduce item if the dot is at the end.
      # @return [Boolean]
      def reduce_item?
        position.negative? # Either -1 or -2
      end

      # The non-terminal symbol that is on the left-side of the production
      # @return [Syntax::NonTerminal]
      def lhs
        production.lhs
      end

      # Return the symbol before the dot.
      # nil is returned if the dot is at the start of the rhs
      # @return [Syntax::GrmSymbol, NilClass]
      def prev_symbol
        before_position = prev_position
        before_position.nil? ? nil : production.rhs[before_position]
      end

      # Return the symbol after the dot.
      # nil is returned if the dot is at the end
      # @return [Syntax::GrmSymbol, NilClass]
      def next_symbol
        position.negative? ? nil : production.rhs[position]
      end

      # Calculate the position of the dot if were moved by
      # one step on the left.
      # @return [Integer]
      def prev_position
        unless @k_prev_position
          case position
            when -2, 0
              result = nil
            when -1
              result = production.rhs.size == 1 ? 0 : production.rhs.size - 1
            else
              result = position - 1
          end
          @k_prev_position = [result]
        end

        @k_prev_position[0]
      end

      # Return true if this dotted item has a dot one place
      # to the right compared to the dotted item argument.
      # @param another [DottedItem]
      # @return [Boolean]
      def successor_of?(another)
        return false if production != another.production

        to_the_left = prev_position
        return false if to_the_left.nil?

        to_the_left == another.position
      end


      private

      # Return the given position after its validation.
      def valid_position(aPosition)
        rhs_size = production.rhs.size
        if aPosition.negative? || aPosition > rhs_size
          raise StandardError, 'Out of bound index'
        end

        if rhs_size.zero?
          -2 # Minus 2 at start/end of empty production
        elsif aPosition == rhs_size
          -1 # Minus 1 at end of non-empty production
        else
          aPosition
        end
      end
    end # class
  end # module
end # module

# End of file
