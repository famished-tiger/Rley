require_relative '../sppf/epsilon_node'
require_relative '../sppf/non_terminal_node'
require_relative '../sppf/alternative_node'
require_relative '../sppf/parse_forest'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Builder GoF pattern. Builder pattern builds a complex object
    # (say, a parse forest) from simpler objects (terminal and non-terminal
    # nodes) and using a step by step approach.
    class ParseForestBuilder
      # Link to parse result
      attr_reader(:parsing)

      # Link to forest object
      attr_reader(:forest)

      # Link to current path
      attr_reader(:curr_path)

      # A hash with pairs of the form: visited parse entry => forest node
      attr_reader(:entry2node)

      # A hash with pairs of the form: parent end entry => path to alternative node
      # This is needed for synchronizing backtracking
      attr_reader(:entry2path_to_alt)

      def initialize(aParsingResult)
        @parsing = aParsingResult
        @curr_path = []
        @entry2node = {}
        @entry2path_to_alt = {}
      end

      def receive_event(anEvent, anEntry, anIndex)
        # puts "Event: #{anEvent} #{anEntry} #{anIndex}"
        case anEntry.vertex
          when GFG::StartVertex
            process_start_entry(anEvent, anEntry, anIndex)

          when GFG::ItemVertex
            process_item_entry(anEvent, anEntry, anIndex)

          when GFG::EndVertex
            process_end_entry(anEvent, anEntry, anIndex)
          else
            fail NotImplementedError
        end
      end

      # Return the current_parent node
      def curr_parent()
        return self.curr_path.last
      end

private

      def process_start_entry(anEvent, anEntry, anIndex)
        self.curr_path.pop while curr_parent.kind_of?(SPPF::AlternativeNode)
        self.curr_path.pop
      end

      def process_end_entry(anEvent, anEntry, anIndex)
        case anEvent
        when :visit
          if curr_path.empty?
            # Build parse forest with root node derived from the
            # accepting parse entry.
            @forest = create_forest(anEntry)
          else
            # if current_parent node matches the lhs non-terminal of anEntry
            # set its origin to the origin of its first child (if not yet assigned)
            curr_parent.range.assign(low: anEntry.origin)
            @entry2node[anEntry] = self.curr_parent
            if anEntry.antecedents.size > 1
              # Store current path for later backtracking
              # puts "Store backtrack context #{anEntry}"
              # puts "path [#{curr_path.join(', ')}]"
              self.entry2path_to_alt[anEntry] = curr_path.dup
              curr_parent.refinement = :or

              create_alternative_node(anEntry.antecedents.first)
            end
          end

        when :backtrack
          # Restore path
          @curr_path = self.entry2path_to_alt[anEntry].dup
          # puts "Restore path #{curr_path.join(', ')}]"
          antecedent_index = curr_parent.subnodes.size
          # puts "Current parent #{curr_parent.to_string(0)}"
          # puts "Antecedent index #{antecedent_index}"
          create_alternative_node(anEntry.antecedents[antecedent_index])

        when :revisit
          # Remove most recent entry in path
          @curr_path.pop

          # Remove also its reference in parent
          curr_parent.subnodes.pop

          # Retrieve the already existing node corresponding to re-visited entry
          popular = @entry2node[anEntry]

          # Share with parent
          curr_parent.add_subnode(popular)

        else
          fail NotImplementedError
        end
      end

=begin
  if it is a dotted item entry (pattern is: X => α . β):
    if there is at least one symbol before the dot
      if that symbol is a non-terminal:

      if that symbol is a terminal # else
        create a token node,
          with same origin as token,
          with same right extent = origin + 1
        add the new node as first child of current_parent
        set curr_entry_set_index to curr_entry_set_index - 1
    if it is a dotted item entry with a beginning dot: # else
      if current_parent node matches the lhs non-terminal of anEntry
        set its origin to the origin of its first child (if not yet assigned)
      remove this node from the path
=end
      def process_item_entry(anEvent, anEntry, anIndex)
        # Retrieve the grammar symbol before the dot (if any)
        prev_symbol = anEntry.prev_symbol
        case prev_symbol
          when Syntax::Terminal
            # create a token node,
            #   with same origin as token,
            #   with same right extent = origin + 1
            # add the new node as first child of current_parent
            create_token_node(anEntry, anIndex)


          when Syntax::NonTerminal
            # create a node with the non-terminal before the dot,
            #   with same right extent as curr_entry_set_index
            # add the new node as first child of current_parent
            # append the new node to the curr_path
            range = { high: anIndex }
            create_non_terminal_node(anEntry, range, prev_symbol)

          when NilClass # Dot at the beginning of production
            if anEntry.vertex.dotted_item.production.empty?
              # Empty rhs => create an epsilon node
              create_epsilon_node(anEntry, anIndex)
            end
        end
      end
      
      # Create an empty parse forest
      def create_forest(anEntry)
        full_range = { low: 0, high: parsing.chart.last_index }
        root_node = create_non_terminal_node(anEntry, full_range)
        return Rley::SPPF::ParseForest.new(root_node)      
      end


      # Factory method. Build and return an SPPF non-terminal node.
      def create_non_terminal_node(anEntry, aRange, nonTSymb = nil)
        non_terminal = nonTSymb.nil? ? anEntry.vertex.non_terminal : nonTSymb
        new_node = Rley::SPPF::NonTerminalNode.new(non_terminal, aRange)
        entry2node[anEntry] = new_node
        add_subnode(new_node)

        return new_node
      end


      # Add an alternative node to the forest
      def create_alternative_node(anEntry)
        alternative = Rley::SPPF::AlternativeNode.new(anEntry.vertex, curr_parent.range)
        add_subnode(alternative)

        return alternative
      end

      def create_token_node(anEntry, anIndex)
        token_position = anIndex - 1
        curr_token = parsing.tokens[token_position]
        new_node = SPPF::TokenNode.new(curr_token, token_position)
        candidate = add_node_to_forest(new_node)
        entry2node[anEntry] = candidate        

        return candidate        
      end


      def create_epsilon_node(anEntry, anIndex)
        new_node = SPPF::EpsilonNode.new(anIndex)
        candidate = add_node_to_forest(new_node)
        entry2node[anEntry] = candidate        

        return candidate
      end
      
      # Add the given node if not yet present in parse forest
      def add_node_to_forest(aNode)
        key_node = aNode.key
        if forest.include?(key_node)
          new_node = forest.key2node[key_node]
        else
          new_node = aNode
          forest.key2node[key_node] = new_node
          # puts "FOREST ADD #{key_node}"
        end
        add_subnode(new_node, false)  

        return new_node
      end


      # Add the given node as sub-node of current parent node
      # Optionally add the node to the current path
      def add_subnode(aNode, addToPath = true)
        curr_parent.add_subnode(aNode) unless curr_path.empty?
        self.curr_path << aNode if addToPath
      end
    end # class
  end # module
end # module

# End of file