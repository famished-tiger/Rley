# frozen_string_literal: true

require_relative 'composite_node'

module Rley
  module RGN
    # A RGN syntax node representing an expression quantified by a ?, * or +.
    class RepetitionNode < CompositeNode
      # @return [Symbol] one of: :zero_or_one, :zero_or_more, :one_or_more
      attr_accessor :repetition

      Repetition2suffix = {
        zero_or_one: '_qmark',
        zero_or_more: '_star',
        exactly_one: '',
        one_or_more: '_plus'
      }.freeze

      # @param child [Array<ASTNode>] sequence of AST nodes
      # @param theRepetition [Symbol] how many times the child node can be repeated
      def initialize(child, theRepetition)
        super([child])
        @repetition = theRepetition
      end

      # @return [RGN::ASTNode]
      def child
        subnodes[0]
      end

      # @return [String]
      def name
        child_name = subnodes[0].name
        "rep_#{child_name}#{Repetition2suffix[repetition]}"
      end

      # @return [String]
      def to_text
        child_text = subnodes[0].to_text
        "rep_#{child_text}#{Repetition2suffix[repetition]}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param visitor [RGN::ASTVisitor] the visitor
      def accept(visitor)
        visitor.visit_repetition_node(self)
      end

      def suffix_qmark
        Repetition2suffix[:zero_or_one]
      end

      def suffix_star
        Repetition2suffix[:zero_or_more]
      end

      def suffix_plus
        Repetition2suffix[:one_or_more]
      end
    end # class
  end # module
end # module
