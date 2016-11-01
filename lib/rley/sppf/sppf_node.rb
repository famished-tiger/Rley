require_relative '../ptree/token_range'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Abstract class. The generalization for all kinds of nodes
    # occurring in a shared packed parse forest.
    class SPPFNode
    
      # A range of indices for tokens matching this node.
      attr_reader(:range)
      
      def initialize(aRange)
        @range = PTree::TokenRange.new(aRange)
      end
      
      # Return the origin (= lower bound of the range 
      # = position of first token matched by the symbol)
      def origin()
        return range.low
      end  
    end # class
  end # module
end # module
# End of file
