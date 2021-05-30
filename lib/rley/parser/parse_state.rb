# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    class ParseState
      attr_reader(:dotted_rule)

      # the position in the input that matches the beginning of the rhs
      # of the production.
      attr_reader(:origin)

      def initialize(aDottedRule, theOrigin)
        @dotted_rule = valid_dotted_rule(aDottedRule)
        @origin = theOrigin
      end

      # Equality comparison. A parse state behaves as a value object.
      def ==(other)
        return true if equal?(other)

        (dotted_rule == other.dotted_rule) &&
          (origin == other.origin)
      end

      # Returns true if the dot is at the end of the rhs of the production.
      # In other words, the complete rhs matches the input.
      def complete?
        dotted_rule.reduce_item?
      end

      # Returns true if the dot is at the start of the rhs of the production.
      def predicted?
        dotted_rule.predicted_item?
      end

      # Next expected symbol in the production
      def next_symbol
        dotted_rule.next_symbol
      end

      # Does this parse state have the 'other' as successor?
      def precedes?(other)
        return false if other == self

        return false unless origin == other.origin

        other_production = other.dotted_rule.production
        return false unless dotted_rule.production == other_production

        prev_position = other.dotted_rule.prev_position
        if prev_position.nil?
          false
        else
          dotted_rule.position == prev_position
        end
      end

      # Give a String representation of itself.
      # The format of the text representation is
      # "format of dotted rule" + " | " + origin
      # @return [String]
      def to_s
        dotted_rule.to_s + " | #{origin}"
      end

      private

      # Return the validated dotted item(rule)
      def valid_dotted_rule(aDottedRule)
        raise StandardError, 'Dotted item cannot be nil' if aDottedRule.nil?

        aDottedRule
      end
    end # class
  end # module
end # module

# End of file
