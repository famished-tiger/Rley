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
    class Production
      # @return [SymbolSeq] The right-hand side (rhs).
      attr_reader(:rhs)

      # @return [NonTerminal] The left-hand side of the rule.
      attr_reader(:lhs)
      
      # @return [Boolean ]A production is generative when all of its 
      # rhs members are generative (that is, they can each generate/derive
      # a non-empty string of terminals).
      attr_writer(:generative)      

      # Provide common alternate names to lhs and rhs accessors

      alias body rhs
      alias head lhs

      def initialize(aNonTerminal, theSymbols)
        @lhs = valid_lhs(aNonTerminal)
        @rhs = SymbolSeq.new(theSymbols)
      end

      # Is the rhs empty?
      # @ return true if the rhs has no members.
      def empty?()
        return rhs.empty?
      end
      
      # Return true iff the production is generative      
      def generative?()
        if @generative.nil?
        end
        
        return @generative
      end      

      private

      # Validation method. Return the validated input argument or
      # raise an exception.
      def valid_lhs(aNonTerminal)
        unless aNonTerminal.kind_of?(NonTerminal)
          msg_prefix = 'Left side of production must be a non-terminal symbol'
          msg_suffix = ", found a #{aNonTerminal.class} instead."
          raise StandardError, msg_prefix + msg_suffix
        end

        return aNonTerminal
      end
    end # class
  end # module
end # module

# End of file
