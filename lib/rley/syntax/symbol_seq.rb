require 'forwardable'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
  
    # A symbol sequence is a suite of grammar symbols
    class SymbolSeq
      extend Forwardable
      def_delegators :@members, :empty?, :size, :[]
      
      # The sequence of symbols
      attr_reader(:members)
      
      def initialize(theSymbols)
        @members = theSymbols.dup
      end
      
      # Equality operator.
      def ==(other)
        return true if other.object_id == self.object_id
        
        case other
        when SymbolSeq then result = other.members == self.members
        when Array then result = other == self.members
        else
          fail StandardError, "Cannot compare a SymbolSeq with a #{other.class}"
        end
        
        return result
      end
    end # class
  
  end # module
end # module

# End of file