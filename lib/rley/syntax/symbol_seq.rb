module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
  
    # A symbol sequence is a suite of grammar symbols
    class SymbolSeq
      # The sequence of symbols
      attr_reader(:members)
      
      def initialize(theSymbols)
        @members = theSymbols.dup
      end
      
      # Tell whether the sequence is empty.
      # @return [true / false] true only if the sequence has no symbol in it.
      def empty?()
        return members.empty?
      end
      
      def size()
        return members.size
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