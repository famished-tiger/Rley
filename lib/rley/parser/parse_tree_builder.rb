require_relative '../syntax/terminal'
require_relative '../syntax/non_terminal'
require_relative '../gfg/end_vertex'
require_relative '../gfg/item_vertex'
require_relative '../gfg/start_vertex'
require_relative '../ptree/non_terminal_node'
require_relative '../ptree/terminal_node'
require_relative '../ptree/parse_tree'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Builder GoF pattern. Builder pattern builds a complex object
    # (say, a parse tree) from simpler objects (terminal and non-terminal
    # nodes) and using a step by step approach.
    class ParseTreeBuilder
      # The sequence of input tokens
      attr_reader(:tokens)

      # Link to tree object
      attr_reader(:tree)

      # Link to current path
      attr_reader(:curr_path)

      # The last parse entry visited
      attr_reader(:last_visitee)

      # A hash with pairs of the form: visited parse entry => tree node
      attr_reader(:entry2node)


      def initialize(theTokens)
        @tokens = theTokens
        @curr_path = []
        @entry2node = {}
      end

      def receive_event(anEvent, anEntry, anIndex)
        # puts "Event: #{anEvent} #{anEntry} #{anIndex}"
        if anEntry.dotted_entry?
          process_item_entry(anEvent, anEntry, anIndex)
        elsif anEntry.start_entry?
          process_start_entry(anEvent, anEntry, anIndex)
        elsif anEntry.end_entry?
          process_end_entry(anEvent, anEntry, anIndex)
        else
          raise NotImplementedError
        end

        @last_visitee = anEntry
      end

      # Return the current_parent node
      def curr_parent()
        return curr_path.last
      end

      private

      def process_start_entry(_anEvent, _anEntry, _anIndex)
        curr_path.pop
      end

      def process_end_entry(anEvent, anEntry, anIndex)
        case anEvent
          when :visit
            # create a node with the non-terminal
            #   with same right extent as curr_entry_set_index
            # add the new node as first child of current_parent
            # append the new node to the curr_path
            range = { low: anEntry.origin, high: anIndex }
            non_terminal = anEntry.vertex.non_terminal
            create_non_terminal_node(anEntry, range, non_terminal)
            @tree = create_tree(curr_parent) unless @last_visitee
          else
            raise NotImplementedError
        end
      end

      def process_item_entry(anEvent, anEntry, anIndex)
        case anEvent
          when :visit
            if anEntry.exit_entry?
              # Previous entry was an end entry (X. pattern)
              # Does the previous entry have multiple antecedent?
              if last_visitee.end_entry? && last_visitee.antecedents.size > 1
                # Store current path for later backtracking
                # puts "Store backtrack context #{last_visitee}"
                # puts "path [#{curr_path.map{|e|e.to_string(0)}.join(', ')}]"
                entry2path_to_alt[last_visitee] = curr_path.dup
                curr_parent.refinement = :or

                create_alternative_node(anEntry)
              end
            end

            # Does this entry have multiple antecedent?
            if anEntry.antecedents.size > 1
              # Store current path for later backtracking
              # puts "Store backtrack context #{anEntry}"
              # puts "path [#{curr_path.map{|e|e.to_string(0)}.join(', ')}]"
              entry2path_to_alt[anEntry] = curr_path.dup
              # curr_parent.refinement = :or

              create_alternative_node(anEntry)
            end

            # Retrieve the grammar symbol before the dot (if any)
            prev_symbol = anEntry.prev_symbol
            case prev_symbol
              when Syntax::Terminal
                # Add node without changing current path
                create_token_node(anEntry, anIndex)

              when NilClass # Dot at the beginning of production
                curr_path.pop if curr_parent.kind_of?(SPPF::AlternativeNode)
            end

          # when :backtrack
          # when :revisit
        end
      end

      # Create an empty parse tree
      def create_tree(aRootNode)
        return Rley::PTree::ParseTree.new(aRootNode)
      end

      # Factory method. Build and return an PTree non-terminal node.
      def create_non_terminal_node(anEntry, aRange, nonTSymb = nil)
        non_terminal = nonTSymb.nil? ? anEntry.vertex.non_terminal : nonTSymb
        new_node = Rley::PTree::NonTerminalNode.new(non_terminal, aRange)
        entry2node[anEntry] = new_node
        add_subnode(new_node)
        # puts "FOREST ADD #{curr_parent.key if curr_parent}/#{new_node.key}"

        return new_node
      end

      # Add an alternative node to the tree
      def create_alternative_node(anEntry)
        vertex = anEntry.vertex
        range = curr_parent.range
        alternative = Rley::PTree::AlternativeNode.new(vertex, range)
        add_subnode(alternative)
        tree.is_ambiguous = true
        # puts "FOREST ADD #{alternative.key}"

        return alternative
      end

      # create a token node,
      #   with same origin as token,
      #   with same right extent = origin + 1
      # add the new node as first child of current_parent
      def create_token_node(anEntry, anIndex)
        token_position = anIndex - 1
        curr_token = tokens[token_position]
        new_node = PTree::TerminalNode.new(curr_token, token_position)
        candidate = add_node_to_tree(new_node)
        entry2node[anEntry] = candidate

        return candidate
      end

      # Add the given node if not yet present in parse tree
      def add_node_to_tree(aNode)
        new_node = aNode
        # puts "FOREST ADD #{key_node}"
        add_subnode(new_node, false)

        return new_node
      end

      # Add the given node as sub-node of current parent node
      # Optionally add the node to the current path
      def add_subnode(aNode, addToPath = true)
        curr_parent.add_subnode(aNode) unless curr_path.empty?
        curr_path << aNode if addToPath
      end
    end # class
  end # module
end # module

# End of file
