require_relative 'terminal_node'
require_relative 'non_terminal_node'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class ParseTree
      # The root node of the tree
      attr_reader(:root)

      # The path to current node
      attr_reader(:current_path)

      def initialize(aProduction, aRange)
        @root = NonTerminalNode.new(aProduction.lhs, aRange)
        @current_path = [ @root ]
        add_children(aProduction, aRange)
      end

      # Return the active node.
      def current_node()
        return current_path.last
      end


      def add_children(aProduction, aRange)
        aProduction.rhs.each do |symb|
          case symb
            when Syntax::Terminal
              new_node = TerminalNode.new(symb,{})
            when Syntax::NonTerminal
              new_node = NonTerminalNode.new(symb,{})
          end

          current_node.add_child(new_node)
        end

        children = current_node.children
        children.first.range = low_bound(aRange)
        children.last.range = high_bound(aRange)
        unless children.empty?
          path_increment = [children.size - 1, children.last]
          @current_path.concat(path_increment)
        end
      end
      
      # Move the current node to the parent node.
      # @param tokenPos [Fixnum] position of the matching input token
      def step_up(tokenPos)
        (pos, last_node) = current_path.pop(2)
        #last_node.range = low_bound({low: tokenPos})
      end
      


      # Move the current node to the previous sibling node.
      # @param tokenPos [Fixnum] position of the matching input token
      def step_back(tokenPos)
        (pos, last_node) = current_path[-2, 2]
        last_node.range = low_bound({low: tokenPos})

        if pos > 0
          current_path.pop(2)
          new_pos = pos - 1
          new_curr_node = current_path.last.children[new_pos]
          current_path << new_pos
          current_path << new_curr_node
          new_curr_node.range = high_bound({high: tokenPos})
        end
      end

      private
        def low_bound(aRange)
          result = case aRange
            when Hash then aRange[:low]
            when TokenRange then aRange.low
          end

          return { low: result }
        end

        def high_bound(aRange)
          result = case aRange
            when Hash then aRange[:high]
            when TokenRange then aRange.high
          end

          return { high: result }
        end

    end # class
  end # module
end # module
# End of file