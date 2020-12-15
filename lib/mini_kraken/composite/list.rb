# frozen_string_literal: true

require_relative 'cons_cell'

module MiniKraken
  module Composite
    # Module that implements convenience methods for manipulating
    # proper lists represented with ConsCell objects.
    module List
      # Factory method for constructing a ConsCell pair.
      # @param obj1 [Term]
      # @param obj2 [Term]
      # @return [Composite::ConsCell]
      def self.cons(obj1, obj2 = nil)
        ConsCell.new(obj1, obj2)
      end

      # Factory method. Build a proper list with elements of given array.
      # @param arr [Array] Array of elements to put in a new list
      # @return [Composite::ConsCell] Head nnode (cell) of created list.
      def self.make_list(arr)
        return cons(nil, nil) if arr.empty?

        reversed = arr.reverse

        reversed.reduce(nil) do |sub_result, elem|
          ConsCell.new(elem, sub_result)
        end
      end
    end # module
  end # module
end # module