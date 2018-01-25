require 'forwardable'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A symbol sequence is a suite of grammar symbols
    class SymbolSeq
      extend Forwardable
      def_delegators :@members, :empty?, :size, :[], :each, :find, :map

      # @return [Array<GrmSymbol>] The sequence of symbols
      attr_reader(:members)

      # Create a sequence of grammar symbols (as in right-hand side of 
      # a production rule).
      # @param theSymbols [Array<GrmSymbol>] An array of symbols.      
      def initialize(theSymbols)
        @members = theSymbols.dup
      end

      # Equality operator.
      # @param other [SymbolSeq|Array]
      # @return [Boolean]
      def ==(other)
        return true if other.object_id == object_id

        case other
          when SymbolSeq then result = other.members == members
          when Array then result = other == members
          else
            msg = "Cannot compare a SymbolSeq with a #{other.class}"
            raise StandardError, msg
        end

        return result
      end
      
      # Returns a string containing a human-readable representation of the 
      # sequence of symbols.
      # @return [String]
      def inspect()
        result = "#<#{self.class.name}:#{self.object_id}"
        symbol_names = self.members.map(&:name)
        result << " @members=#{symbol_names}>"
        return result
      end
      
      
    end # class
  end # module
end # module

# End of file
