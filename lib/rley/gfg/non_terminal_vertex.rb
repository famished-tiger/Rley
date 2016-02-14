require_relative 'vertex'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Represents a specialized vertex in a grammar flow graph 
    # that is associated to a given non-terminal symbol.
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class NonTerminalVertex < Vertex
        attr_reader :non_terminal
      
      def initialize(aNonTerminal)
        super()
        @non_terminal = aNonTerminal
      end

    end # class
  end # module
end # module

# End of file