# frozen_string_literal: true

require 'set'
require_relative 'cons_cell'

module MiniKraken
  module Composite
    # Factory class.
    # Purpose: to create Fiber specialized in the visit of cons cells.
    class ConsCellVisitor
      # Build a depth-first in-order expression tree visitor.
      # The visitor is implemented as a Fiber.
      # The Fiber yields couples of the form: [member, visitee]
      # where member is one of :car, :cdr
      # The end of visit is signalled with the couple [:stop, nil]
      # @param aCell [ConsCell]
      # @return [Fiber] A Fiber that yields couples
      def self.df_visitor(aCell)
        first = aCell	# The visit will start from the provided cons cell
        # puts "#{__callee__} called with #{aCell.object_id.to_s(16)}"
        visitor = Fiber.new do |skipping|
          # Initialization part: will run once
          visitees = Set.new # Keep track of the conscell already visited
          visit_stack = first.nil? ? [] : [[:car, first]] # The LIFO queue of cells to visit

          until visit_stack.empty?	# Traversal part (as a loop)
            side, cell = visit_stack.pop
            next if visitees.include?(cell) && side == :car

            visitees << cell if cell.kind_of?(ConsCell)

            skip_children = Fiber.yield [side, cell]
            next if skip_children || skipping

            skipping = false
            if cell.is_a?(ConsCell)
              visit_stack.push([:cdr, cell.cdr])
              visit_stack.push([:car, cell.car])
            end
          end

          # Send stop mark
          Fiber.yield [:stop, nil]
        end

        return visitor
      end

    end # class
  end # module
end # module
