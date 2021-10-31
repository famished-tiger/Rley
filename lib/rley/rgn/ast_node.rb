# frozen_string_literal: true

module Rley
  module RGN
    # Abstract class.
    # Instances of its subclasses represent nodes of an abstract syntax tree
    # that is the product of the parse of an input text.
    class ASTNode
      # @return [Hash]
      attr_reader :annotation

      def initialize
        @annotation = {}
      end

      def annotation=(aMapping)
        repeat_key = 'repeat'
        @repetition = aMapping.delete(repeat_key) if aMapping.include?(repeat_key)
        @annotation = aMapping
      end

      def annotation_to_text
        map_arr = []
        @annotation.each_pair do |key, val|
          literal = val.kind_of?(String) ? "'#{val}'" : val
          map_arr << "#{key}: #{literal}"
        end

        "{ #{map_arr.join(', ')} }"
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
