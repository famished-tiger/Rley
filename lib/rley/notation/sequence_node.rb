# frozen_string_literal: true

require_relative 'ast_node'

module Rley
  module Notation
    # A syntax node for a sequence of AST nodes
    class SequenceNode < ASTNode
      # @return [Array<ASTNode>]
      attr_reader :subnodes
      
      attr_accessor :constraints
      
      # @param aPosition [Rley::Lexical::Position] Start position.
      # @param sequence [Array<ASTNode>] sequence of AST nodes
      # @param theRepetition [Symbol] indicates how many times the symbol can be repeated
      def initialize(aPosition, sequence, theRepetition = nil)
        super(aPosition)
        @subnodes = sequence
        repetition=(theRepetition) if theRepetition
        @constraints = []
      end

      def size
        subnodes.size
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param visitor [Notation::ASTVisitor] the visitor
      def accept(visitor)
        visitor.visit_sequence_node(self)
      end
    end # class
  end # module
end # module
