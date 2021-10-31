# frozen_string_literal: true

require_relative 'composite_node'

module Rley
  module RGN
    # A syntax node for a sequence of AST nodes
    class SequenceNode < CompositeNode
      def name
        result = +''
        subnodes.each do |sn|
          result << "_#{sn.name}"
        end

        "seq#{result}"
      end

      def to_text
        arr = subnodes.map(&:to_text)
        arr.join(' ')
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param visitor [RGN::ASTVisitor] the visitor
      def accept(visitor)
        visitor.visit_sequence_node(self)
      end
    end # class
  end # module
end # module
