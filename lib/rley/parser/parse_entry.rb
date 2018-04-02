require_relative '../gfg/start_vertex'
require_relative '../gfg/end_vertex'
require_relative '../gfg/item_vertex'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Responsibilities:
    # - To know whether the vertex is a start, end or item vertex
    # - To know the next symbol to expect
    class ParseEntry
      # @return [GFG::Vertex] Link to a vertex of the GFG
      attr_reader(:vertex)

      # @return [Array<ParseEntry>] Links to preceding parse entries
      attr_reader(:antecedents)

      # the position in the input that matches the beginning of the rhs
      # of the production.
      # @return [Integer]
      attr_reader(:origin)

      # @param aVertex [GFG::Vertex]
      # @param theOrigin [Integer]
      def initialize(aVertex, theOrigin)
        @vertex = valid_vertex(aVertex)
        @origin = theOrigin
        @antecedents = []
      end

      # Returns a string containing a human-readable representation of the
      # production.
      # @return [String]
      def inspect()
        result = selfie
        result << ' @antecedents=['
        antecedents.each do |antec|
          result << antec.selfie
        end
        result << ']>'

        return result
      end

      # Add a link to an antecedent parse entry
      def add_antecedent(anAntecedent)
        antecedents << anAntecedent unless antecedents.include?(anAntecedent)
      end

      # Equality comparison. A parse entry behaves as a value object.
      def ==(other)
        return true if object_id == other.object_id

        result = (vertex == other.vertex) && (origin == other.origin)
        return result
      end

      # Returns true iff the vertex is a start vertex (i.e. of the form: .X)
      def start_entry?()
        return vertex.kind_of?(GFG::StartVertex)
      end

      # Returns true iff the vertex is at the start of rhs
      # (i.e. of the form: X => .Y
      def entry_entry?()
        return false unless vertex.kind_of?(GFG::ItemVertex)

        return vertex.dotted_item.at_start?
      end

      # Returns true iff the vertex corresponds to a dotted item
      # X => Y
      def dotted_entry?
        return vertex.kind_of?(GFG::ItemVertex)
      end

      # Returns true iff the vertex is at end of rhs (i.e. of the form: X => Y.)
      def exit_entry?()
        return vertex.complete?
      end

      # Returns true iff the vertex is an end vertex (i.e. of the form: X.)
      def end_entry?()
        return vertex.kind_of?(GFG::EndVertex)
      end

      # Return the symbol before the dot (if any)
      def prev_symbol()
        return vertex.prev_symbol
      end

      # Return the symbol after the dot (if any)
      def next_symbol()
        return vertex.next_symbol
      end

      # Return true if the entry has no antecedent entry
      def orphan?()
        return antecedents.empty?
      end

=begin
      # Returns true if the dot is at the end of the rhs of the production.
      # In other words, the complete rhs matches the input.
      def complete?()
        return vertex.reduce_item?
      end

      # Returns true if the dot is at the start of the rhs of the production.
      def predicted?()
        return vertex.predicted_item?
      end

      # Next expected symbol in the production
      def next_symbol()
        return vertex.next_symbol
      end

      # Does this parse state have the 'other' as successor?
      def precedes?(other)
        return false if self == other

        return false unless origin == other.origin
        other_production = other.dotted_rule.production
        return false unless dotted_rule.production == other_production

        prev_position = other.dotted_rule.prev_position
        if prev_position.nil?
          result = false
        else
          result = dotted_rule.position == prev_position
        end

        return result
      end
=end

      # Give a String representation of itself.
      # The format of the text representation is
      # "format of dotted rule" + " | " + origin
      # @return [String]
      def to_s()
        return vertex.label + " | #{origin}"
      end

      protected

      # Returns a human-readable and partial representation of itself.
      # @return [String]
      def selfie()
        result = "#<#{self.class.name}:#{object_id}"
        result << " @vertex=<#{vertex.class.name}:#{vertex.object_id}"
        result << " label=#{vertex.label}>"
        result << " @origin=#{origin}"

        return result
      end

      private


      # Return the validated GFG vertex
      def valid_vertex(aVertex)
        raise StandardError, 'GFG vertex cannot be nil' if aVertex.nil?

        return aVertex
      end
    end # class
  end # module
end # module

# End of file
