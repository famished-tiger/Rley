# frozen_string_literal: true

require_relative 'sequence_node'

module Rley
  module Notation
    # A syntax node representing an expression bracketed by parentheses.
    class GroupingNode < SequenceNode
      # @param aPosition [Rley::Lexical::Position] Start position.
      # @param sequence [Array<ASTNode>] sequence of AST nodes
      # @param theRepetition [Symbol] indicates how many times the symbol can be repeated
      def initialize(aPosition, sequence, theRepetition = nil)
        super(aPosition, sequence, theRepetition)
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param visitor [Notation::ASTVisitor] the visitor
      def accept(visitor)
        visitor.visit_grouping_node(self)
      end
    end # class
  end # module
end # module
