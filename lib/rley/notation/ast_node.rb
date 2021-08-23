# frozen_string_literal: true

module Rley
  module Notation
    # Abstract class.
    # Instances of its subclasses represent nodes of an abstract syntax tree
    # that is the product of the parse of an input text.
    class ASTNode
      # @return [Rley::Lexical::Position] Position of the entry in the input stream.
      attr_reader :position

      # @return [Symbol]
      attr_accessor :repetition

      # @return [Hash]
      attr_reader :annotation

      # @param aPosition [Rley::Lexical::Position] Position of the entry in the input stream.
      def initialize(aPosition)
        @position = aPosition
        @repetition = :exactly_one
        @annotation = {}
      end

      def annotation=(aMapping)
        repeat_key = 'repeat'
        @repetition = aMapping.delete(repeat_key) if aMapping.include?(repeat_key)
        @annotation = aMapping
      end

      # Notification that the parsing has successfully completed
      def done!
        # Default: do nothing ...
      end

      # Abstract method (must be overriden in subclasses).
      # Part of the 'visitee' role in Visitor design pattern.
      # @param _visitor [LoxxyTreeVisitor] the visitor
      def accept(_visitor)
        raise NotImplementedError
      end
    end # class
  end # module
end # module
