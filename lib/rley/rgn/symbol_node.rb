# frozen_string_literal: true

require_relative 'ast_node'

module Rley
  module RGN
    # A syntax node for a grammar symbol occurring in rhs of a rule.
    # symbol nodes are leaf nodes of RRN parse trees.
    class SymbolNode < ASTNode
      # @return [Rley::Lexical::Position] Position of the entry in the input stream.
      attr_reader :position

      # @return [String] name of grammar symbol
      attr_reader :name

      # @param aPosition [Rley::Lexical::Position] Position of the entry in the input stream.
      # @param aName [String] name of grammar symbol
      def initialize(aPosition, aName)
        super()
        @position = aPosition
        @name = aName
      end

      # @return [String] name of grammar symbol
      def to_text
        annotation.empty? ? name : "#{name} #{annotation_to_text}"
      end

      # Abstract method (must be overriden in subclasses).
      # Part of the 'visitee' role in Visitor design pattern.
      # @param visitor [LoxxyTreeVisitor] the visitor
      def accept(visitor)
        visitor.visit_symbol_node(self)
      end
    end # class
  end # module
end # module
