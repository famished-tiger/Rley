# frozen_string_literal: true

require_relative 'non_terminal_vertex'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # TODO: change definition.
    # Represents a specialized vertex in a grammar flow graph
    # that is associated to a given non-terminal symbol.
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class EndVertex < NonTerminalVertex
      def label
        "#{non_terminal}."
      end
    end # class
  end # module
end # module

# End of file
