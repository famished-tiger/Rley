require_relative 'symbol_seq'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
  
    # In a context-free grammar, a production is a rule in which
    # its left-hand side (LHS) consists solely of a non-terminal symbol
    # and the right-hand side (RHS) consists of a sequence of symbols.
    # The symbols in RHS can be either terminal or non-terminal symbols.
    # The rule stipulates that the LHS is equivalent to the RHS,
    # in other words every occurrence of the LHS can be substituted to
    # corresponding RHS.
    # Implementation note: the object id of the production is taken as its LHS.
    class Production
      # The right-hand side (rhs) consists of a sequence of grammar symbols
      attr_reader(:rhs)
      
      # The left-hand side of the rule. It must be a non-terminal symbol
      attr_reader(:lhs)
      
      # Provide common alternate names to lhs and rhs accessors
      
      alias :body :rhs
      alias :head :lhs
      
      def initialize(aNonTerminal, theSymbols)
        @lhs = aNonTerminal
        @rhs = SymbolSeq.new(theSymbols)
      end
      
      # Is the rhs empty?
      # @ return true if the rhs has no members.      
      def empty?()
        return rhs.empty?
      end

    end # class
  
  end # module
end # module

# End of file