# frozen_string_literal: true

require_relative 'ast_node'

module Rley
  module Notation
    # A syntax node for a grammar symbol occurring in rhs of a rule
    class SymbolNode < ASTNode
      # @return [String] name of grammar symbol
      attr_reader :name

      # @param aPosition [Rley::Lexical::Position] Position of the entry in the input stream.
      # @param aName [String] name of grammar symbol
      # @param theRepetition [Symbol] indicates how many times the symbol can be repeated
      def initialize(aPosition, aName, theRepetition = nil)
        super(aPosition)
        @name = aName
        self.repetition = theRepetition if theRepetition
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
