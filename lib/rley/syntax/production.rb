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
      # The right-hand side (rhs) consists of a sequence of grammar symbols
      attr_reader(:rhs)

      # The left-hand side of the rule. It must be a non-terminal symbol
      attr_reader(:lhs)

      # Provide common alternate names to lhs and rhs accessors

      alias_method :body, :rhs
      alias_method :head, :lhs

      def initialize(aNonTerminal, theSymbols)
        @lhs = valid_lhs(aNonTerminal)
        @rhs = SymbolSeq.new(theSymbols)
      end

      # Is the rhs empty?
      # @ return true if the rhs has no members.
      def empty?()
        return rhs.empty?
      end

      private

      # Validation method. Return the validated input argument or
      # raise an exception.
      def valid_lhs(aNonTerminal)
        unless aNonTerminal.kind_of?(NonTerminal)
          msg_prefix = 'Left side of production must be a non-terminal symbol'
          msg_suffix = ", found a #{aNonTerminal.class} instead."
          fail StandardError, msg_prefix + msg_suffix
        end

        return aNonTerminal
      end
    end # class
  end # module
end # module

# End of file
