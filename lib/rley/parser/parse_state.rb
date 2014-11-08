module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace

    class ParseState
      attr_reader(:dotted_rule)

      # the position in the input at which the matching
      # of the production began
      attr_reader(:origin)

      def initialize(aDottedRule, theOrigin)
        @dotted_rule = aDottedRule
        @origin = theOrigin
      end

      # Equality comparison. A parse state behaves as a value object.
      def ==(other)
        return true if self.object_id == other.object_id

        if (dotted_rule == other.dotted_rule) && (origin == other.origin)
          result = true
        else
          result = false
        end

        return result
      end

    end # class

  end # module
end # module

# End of file