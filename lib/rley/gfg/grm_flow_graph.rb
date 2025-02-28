# frozen_string_literal: true

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
    # A Grammar Flow Graph (GFG) represents the parsing states of productions
    # rules from a context-free grammar. This representation is based on a
    # directed graph structure. The parsing process can then be re-formulated
    # as a path problem in the graph. The theory behind GFGs can be found in
    # papers. The first article on GFG can be found here:
    # https://apps.cs.utexas.edu/tech_reports/reports/tr/TR-2102.pdf
    # There are three types of vertex in a GFG:
    # start vertex, end vertex and item vertex.
    # For each non-terminal symbol N of the grammar, there is:
    # a start vertex with label '.N'
    # an end vertex with label 'N.'
    # For each production rule of the grammar:
    # N => s1 s2 s3 (...) sk
    # I.e. a rule with k grammar symbols in its right-handed side.
    # For such a rule there will be k + 1 item vertices. By convention,
    # the first item vertex is labelled as 'N => . s1 s2 s3 (...) sk'
    # the second item vertex is labelled as 'N => s1 . s2 s3 (...) sk'
    # the third item vertex is labelled as 'N => s1 s2 . s3 (...) sk'
    # and so on. In other words, the labels are obtained by moving a dot
    # in successive positions in the rhs. The dot represents the
    # parse progress for the production rule. Symbols on the left of the
    # dot represent the symbols that were successfully matched in the input.
    # A GFG has three types of directed edges linking the vertices.
    # call edge, return edge and scan edge.
    class GrmFlowGraph
      # @return [Array<Vertex>] The set of all vertices in the graph
      attr_reader :vertices

      # The vertex marked as start node of the graph
      # @return [StartVertex>]
      attr_reader :start_vertex

      # A Hash with pairs of the form: non-terminal symbol => start node
      attr_reader :start_vertex_for

      # A Hash with pairs of the form: non-terminal symbol => end node
      attr_reader :end_vertex_for

      # Constructor.
      # @param theDottedItems [Array<DottedItem>] an array of the dotted items
      # of the grammar.
      def initialize(theDottedItems)
        @vertices = []
        @start_vertex_for = {}
        @end_vertex_for = {}

        build_graph(theDottedItems)
      end

      # Returns a string containing a human-readable representation of the
      # production.
      # @return [String]
      def inspect
        result = +"#<#{self.class.name}:#{object_id}"
        result << ' @vertices=['
        list = vertices.map { |v| "#<#{v.selfie}>" }
        result << list.join(', ')
        result << '] '
        edges = []
        vertices.each do |v|
          edges << v.edges do |e|
            result << "#{v.object_id} #{e.inspect}"
          end
        end
        result << "edges=[#{edges.join(",\n ")}]>"
        result
      end

      # Retrieve the vertex with given vertex label.
      # @param aVertexLabel [String] the label of a vertex from the graph
      # @return [Vertex] the vertex with the given label, otherwise nil.
      def find_vertex(aVertexLabel)
        vertices.find { |a_vertex| a_vertex.label == aVertexLabel }
      end

      # Perform a diagnosis of the grammar elements (symbols and rules)
      # in order to detect:
      # If one wants to remove useless rules, then do first:
      # elimination of non-generating symbols
      # then elimination of unreachable symbols
      def diagnose
        mark_unreachable_symbols
      end

      Branching = Struct.new(:vertex, :in_edge, :to_visit, :visited) do
        def initialize(aVertex, aCallEdge)
          super(aVertex)
          self.in_edge = aCallEdge
          self.to_visit = aVertex.edges.dup
          self.visited = []
        end

        def done?
          to_visit.empty?
        end

        def next_edge
          next_one = to_visit.shift
          visited << next_one.successor unless next_one.nil?

          return next_one
        end
      end

      # Walk over all the vertices of the graph that are reachable from a given
      # start vertex. This is a depth-first graph traversal.
      # @param aStartVertex [StartVertex] the depth-first traversal begins
      #   from here
      # @param _visitAction [Proc] block called when a new graph vertex is found
      # rubocop: disable Lint/Loop
      def traverse_df(aStartVertex, &_visitAction)
        visited = Set.new
        stack = []
        visitee = aStartVertex
        curr_edge = nil

        begin
          # print_vertex( 'Traversing', visitee)

          first_time = !visited.include?(visitee)
          if first_time
            yield(visitee)
            visited << visitee
          end

          case visitee
            when Rley::GFG::StartVertex
              if first_time
                stack.push(Branching.new(visitee, curr_edge))
                curr_edge = stack.last.next_edge
              elsif curr_edge.nil?
                # Error probably caused by missing terminal symbol object
                msg = "Undefined grammar symbol #{visitee.label.sub(/^\./, '')}"
                raise StandardError, msg
              else
                # Skip both start and end vertices
                # Retrieve the corresponding return edge
                curr_edge = get_matching_return(curr_edge)
              end

            when Rley::GFG::EndVertex
              if stack.last.done?
                popped = stack.pop
                break if stack.empty?

                # puts "Popped!"
                return_key = popped.in_edge.key.sub(/^CALL/, 'RET')
                curr_edge = visitee.edges.find { |e| e.key == return_key }
              else
                curr_edge = stack.last.next_edge
              end

            else
              # All other vertex types have only one successor
              curr_edge = visitee.edges[0]
          end
          visitee = curr_edge.successor unless curr_edge.nil?
        end until stack.empty?
        # Now process the end vertex matching the initial start vertex
        last_one = end_vertex_for[aStartVertex.non_terminal]
        yield(last_one) unless visited.include?(last_one)
      end
      # rubocop: enable Lint/Loop

      private

      def add_vertex(aVertex)
        raise StandardError, 'GFG vertex cannot be nil' if aVertex.nil?

        # TODO: make setting of start vertex more robust
        @start_vertex = aVertex if vertices.empty?
        vertices << aVertex
      end

      # For debugging purposes
      def print_vertex(aText, aVertex)
        print "#{aText} "
        if aVertex.kind_of?(NonTerminalVertex)
          puts "#{aVertex.class} #{aVertex.non_terminal.name}"
        else
          p(aVertex.label)
        end
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
        all_nterms = Set.new
        productions.each do |prod|
          all_nterms << prod.lhs
          nterms_of_rhs = prod.rhs.members.select do |symb|
            symb.kind_of?(Syntax::NonTerminal)
          end
          all_nterms.merge(nterms_of_rhs)
        end
        all_nterms.each { |nterm| build_start_end_for(nterm) }
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
        # rubocop: disable Lint/RedundantSafeNavigation
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
          if prev_symbol&.kind_of?(Syntax::NonTerminal)
            build_shortcut_edge(prev_vertex, new_vertex)
          end
          prev_vertex = new_vertex
        end
      end
      # rubocop: enable Lint/RedundantSafeNavigation

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
        ReturnEdge.new(end_vertex, return_vertex) if end_vertex
      end

      def build_shortcut_edge(fromVertex, toVertex)
        ShortcutEdge.new(fromVertex, toVertex)
      end

      # Retrieve the return edge that matches the given
      # call edge.
      def get_matching_return(aCallEdge)
        # Calculate key of return edge from the key of call edge
        ret_key = aCallEdge.key.sub(/CALL/, 'RET')

        # Retrieve the corresponding end vertex
        end_vertex = end_vertex_for[aCallEdge.successor.non_terminal]

        # Retrieve the return edge with specified key
        return_edge = end_vertex.edges.find { |edge| edge.key == ret_key }
        return return_edge
      end

      # Mark non-terminal symbols that cannot be derived from the start symbol.
      # In a GFG, a non-terminal symbol N is unreachable if there is no path
      # from the start symbol to the start node .N
      def mark_unreachable_symbols
        # Mark all non-terminals as unreachable
        start_vertex_for.each_value do |a_vertex|
          a_vertex.non_terminal.unreachable = true
        end

        # Now traverse graph from start vertex of graph
        # and mark all visited non-terminals as reachable
        traverse_df(start_vertex) do |a_vertex|
          # print_vertex('  Visiting', a_vertex)
          if a_vertex.kind_of?(StartVertex)
            a_vertex.non_terminal.unreachable = false
          end
        end
      end
    end # class
  end # module
end # module

# End of file
