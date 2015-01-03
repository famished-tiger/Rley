require 'ostruct' # TODO delete this
require_relative '../ptree/terminal_node'
require_relative '../ptree/non_terminal_node'
require_relative '../ptree/parse_tree'


module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Builder GoF pattern. Builder pattern builds a complex object
    # (say, a parse tree) from simpler objects (terminal and non-terminal
    # nodes) and using a step by step approach.
    class ParseTreeBuilder
      attr_reader(:root)
      attr_reader(:current_path)

      def initialize(aStartProduction, aRange)
        @current_path = []
        start_symbol = aStartProduction.lhs
        add_node(start_symbol, aRange)
        use_production(aStartProduction, aRange)
        move_down
      end

      # Return the active node.
      def current_node()
        return current_path.last
      end
      
      # Factory method.
      def parse_tree()
        return PTree::ParseTree.new(root)
      end


      # Given that the current node is also lhs of the production
      # associated with the complete parse state,
      # Then add the rhs constituents as child nodes of the current node.
      # Assumption: current node is lhs of the production association
      # with the parse state.
      # @param aCompleteState [ParseState] A complete parse state
      # (dot is at end of rhs)
      def use_complete_state(aCompleteState)
        prod = aCompleteState.dotted_rule.production
        use_production(prod, {low: aCompleteState.origin})
      end

      # Given that the current node is a non-terminal
      # Make its last child node the current node.
      def move_down()
        curr_node = current_node
        unless curr_node.is_a?(PTree::NonTerminalNode)
          msg = "Current node isn't a non-terminal node #{curr_node.class}"
          fail StandardError, msg
        end
        children = curr_node.children
        path_increment = [children.size - 1, children.last]
        @current_path.concat(path_increment)
      end


      # Make the predecessor of current node the
      # new current node.
      def move_back()   
        begin
          if current_path.length == 1
            msg = 'Cannot move further back'
            fail StandardError, msg
          end
          (parent, pos, child_node) = current_path[-3, 3]
          current_path.pop(2)
          if pos > 0
            new_pos = pos - 1
            new_curr_node = parent.children[new_pos]
            current_path << new_pos
            current_path << new_curr_node
            range = high_bound(child_node.range.low)
          end
        end while pos == 0 && new_curr_node.is_a?(PTree::NonTerminalNode)
      end


      # Add a child node to the current node.
      def add_node(aSymbol, aRange)
        # Create the node
        a_node = new_node(aSymbol, aRange)

        # Add it to the current node
        add_child(a_node)
      end

      # Set unbound endpoints of current node range
      # to the given range.
      def range=(aRange)
        curr_node = current_node
        return if curr_node.nil?
        lower = low_bound(aRange)
        unless lower.nil?
          current_node.range = lower
          if curr_node.is_a?(PTree::TerminalNode)
            current_node.range = high_bound(lower[:low] + 1)
          end
        end  
        upper = high_bound(aRange)
        current_node.range = upper unless upper.nil?
      end

      private

      def new_node(aSymbol, aRange)
        case aSymbol
          when Syntax::Terminal
            new_node = PTree::TerminalNode.new(aSymbol, aRange)
          when Syntax::NonTerminal
            new_node = PTree::NonTerminalNode.new(aSymbol, aRange)
        end

        return new_node
      end

      # Add children nodes to current one.
      # The children correspond to the members of the rhs of the production.
      def use_production(aProduction, aRange)
        prod = aProduction
        curr_node = current_node

        if curr_node.symbol != prod.lhs
          msg = "Current node is a #{curr_node.symbol} instead of #{prod.lhs}"
          fail StandardError, msg
        end
        self.range = aRange
        prod.rhs.each { |symb| add_node(symb, {}) }

        unless curr_node.children.empty?
          curr_node.children.first.range.assign({ low: curr_node.range.low })
          curr_node.children.last.range.assign({ high: curr_node.range.high })
        end
      end      

      # Add the given node as child node of current node
      def add_child(aNode)
        curr_node = current_node

        if curr_node.nil?
          self.root = aNode
        else
          curr_node.children << aNode
        end
      end

      # Set the root node of the tree.
      def root=(aNode)
        @root = aNode
        @current_path = [ @root ]
        root.range = low_bound(0)
      end


      def low_bound(aRange)
        result = case aRange
          when Fixnum then aRange
          when Hash then aRange[:low]
          when PTree::TokenRange then aRange.low
        end

        return { low: result }
      end

      def high_bound(aRange)
        result = case aRange
          when Fixnum then aRange
          when Hash then aRange[:high]
          when PTree::TokenRange then aRange.high
        end

        return { high: result }
      end
    end # class
  end # module
end # module

# End of file