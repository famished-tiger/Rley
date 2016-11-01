require_relative 'start_vertex'
require_relative 'end_vertex'
require_relative 'item_vertex'
require_relative 'epsilon_edge'
require_relative 'call_edge'
require_relative 'return_edge'
require_relative 'scan_edge'
require_relative 'shortcut_edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # TODO: add definition
    class GrmFlowGraph
      # The set of all vertices in the graph
      attr_reader :vertices

      # The vertex marked as start node of the graph
      attr_reader :start_vertex

      # A Hash with pairs of the form: non-terminal symbol => start node
      attr_reader :start_vertex_for

      # A Hash with pairs of the form: non-terminal symbol => end node
      attr_reader :end_vertex_for

      def initialize(theDottedItems)
        @vertices = []
        @start_vertex_for = {}
        @end_vertex_for = {}

        build_graph(theDottedItems)
      end

      # Return the vertex with given vertex label.
      def find_vertex(aVertexLabel)
        vertices.find { |a_vertex| a_vertex.label == aVertexLabel }
      end

      private

      def add_vertex(aVertex)
        raise StandardError, 'GFG vertex cannot be nil' if aVertex.nil?

        # TODO: make setting of start vertex more robust
        @start_vertex = aVertex if vertices.empty?
        vertices << aVertex
      end

      def build_graph(theDottedItems)
        build_all_starts_ends(theDottedItems)

        curr_prod = nil
        theDottedItems.each_with_index do |d_item, index_item|
          next unless curr_prod.nil? || curr_prod != d_item.production
          # Another production found...
          curr_prod = d_item.production
          if curr_prod.empty?
            add_single_item(d_item)
          else
            # Add vertices and edges for dotted items of production
            augment_graph(theDottedItems, index_item)
          end
        end
      end

      # For each non-terminal from the grammar, say N
      # Add the .N and N. vertices to the graph
      def build_all_starts_ends(theDottedItems)
        productions_raw = theDottedItems.map(&:production)
        productions = productions_raw.uniq
        productions.each { |prod| build_start_end_for(prod.lhs) }
      end

      # if there is not yet a start vertex labelled .N in the GFG:
      #   add a start vertex labelled .N
      #   add an end vertex labelled N.
      def build_start_end_for(aNonTerminal)
        return if start_vertex_for.include?(aNonTerminal)

        new_start_vertex = StartVertex.new(aNonTerminal)
        start_vertex_for[aNonTerminal] = new_start_vertex
        add_vertex(new_start_vertex)

        new_end_vertex = EndVertex.new(aNonTerminal)
        end_vertex_for[aNonTerminal] = new_end_vertex
        add_vertex(new_end_vertex)
      end


      def add_single_item(aDottedItem)
        new_vertex = ItemVertex.new(aDottedItem)
        add_vertex(new_vertex)
        build_entry_edge(new_vertex)
        build_exit_edge(new_vertex)
      end

      # Add vertices and edges for dotted items derived from same production
      # production of the form: N => α[1] ... α[n] (non-empty rhs):
      # # Rule 3
      # create n+1 nodes labelled:
      #   N => . α[1] ... α[n], N => α[1] . ... α[n], ..., N => α[1] ... α[n] .
      # add an epsilon entry edge: .N -> N => . α[1] ... α[n]
      # add an epsilon exit edge: N => α[1] ... α[n] . -> N.
      # For each symbol in rhs:
      #   if it is a terminal, say a:
      #     Rule 4
      #     add a scan edge: N => α[1] .a  α[n] -> N => α[1] a. α[n]
      #   else # non-terminal symbol A in rhs:
      #     Rule 5
      #     add a call edge: N => α[1] .A  α[n] -> .A
      #     add a return edge: A. -> N => α[1] A.  α[n]
      #     add a shortcut edge:
      # ( N => α[1] .A  α[n] ) -> ( N => α[1] A.  α[n] )
      def augment_graph(theDottedItems, firstItemPos)
        production = theDottedItems[firstItemPos].production
        max_index = production.rhs.size + 1
        prev_vertex = nil

        (0...max_index).each do |index|
          current_item = theDottedItems[firstItemPos + index]
          new_vertex = ItemVertex.new(current_item)
          add_vertex(new_vertex)
          build_exit_edge(new_vertex) if current_item.reduce_item? # At end?
          if current_item.at_start?
            build_entry_edge(new_vertex)
          else
            # At least one symbol before the dot
            # Retrieve the symbol before the dot...
            prev_symbol = current_item.prev_symbol
            if prev_symbol.kind_of?(Syntax::Terminal)
              build_scan_edge(vertices[-2], new_vertex)
            else
              # ...non-terminal
              build_call_return_edges(vertices[-2], new_vertex)
            end
          end

          prev_symbol = current_item.prev_symbol
          if prev_symbol && prev_symbol.kind_of?(Syntax::NonTerminal)
            build_shortcut_edge(prev_vertex, new_vertex)
          end
          prev_vertex = new_vertex
        end
      end

      # Create an entry edge for the given vertex
      def build_entry_edge(theVertex)
        # Retrieve corresponding start vertex (for lhs non-terminal)
        start_vertex = start_vertex_for[theVertex.dotted_item.production.lhs]

        # Create an edge start_vertex -> the vertex
        EpsilonEdge.new(start_vertex, theVertex)
      end

      # Create an exit edge for the given vertex
      def build_exit_edge(theVertex)
        # Retrieve corresponding end vertex (for lhs non-terminal)
        end_vertex = end_vertex_for[theVertex.dotted_item.production.lhs]

        # Create an edge the vertex -> end_vertex
        EpsilonEdge.new(theVertex, end_vertex)
      end

      # Create a scan edge between two vertices.
      # These two vertices are assumed to correspond to two
      # consecutive dot positions separated by a terminal symbol
      def build_scan_edge(fromVertex, toVertex)
        ScanEdge.new(fromVertex, toVertex, fromVertex.dotted_item.next_symbol)
      end

      def build_call_return_edges(calling_vertex, return_vertex)
        nt_symbol = calling_vertex.dotted_item.next_symbol

        # Retrieve corresponding start vertex
        start_vertex = start_vertex_for[nt_symbol]
        # Create an edge 'calling' vertex -> start vertex
        CallEdge.new(calling_vertex, start_vertex)

        # Retrieve corresponding end vertex
        end_vertex = end_vertex_for[nt_symbol]
        # Create an edge end vertex -> return vertex
        ReturnEdge.new(end_vertex, return_vertex)
      end

      def build_shortcut_edge(fromVertex, toVertex)
        ShortcutEdge.new(fromVertex, toVertex)
      end
    end # class
  end # module
end # module

# End of file
