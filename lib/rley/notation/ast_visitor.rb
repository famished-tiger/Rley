module Rley
  module Notation
    class ASTVisitor
      # Link to the top node to visit
      attr_reader(:top)

      # List of objects that subscribed to the visit event notification.
      attr_reader(:subscribers)

      # Build a visitor for the given top.
      # @param aTop [Notation::ASTNode] the parse tree to visit.
      def initialize(aTop)
        raise StandardError if aTop.nil?

        @top = aTop
        @subscribers = []
      end

      # Add a subscriber for the visit event notifications.
      # @param aSubscriber [Object]
      def subscribe(aSubscriber)
        subscribers << aSubscriber
      end

      # Remove the given object from the subscription list.
      # The object won't be notified of visit events.
      # @param aSubscriber [Object]
      def unsubscribe(aSubscriber)
        subscribers.delete_if { |entry| entry == aSubscriber }
      end

      # The signal to begin the visit of the top.
      def start
        top.accept(self)
      end

      # Visit event. The visitor is about to visit the ptree.
      # @param aParseTree [Rley::PTree::ParseTree] the ptree to visit.
      def start_visit_ptree(aParseTree)
        broadcast(:before_ptree, aParseTree)
      end

      # Visit event. The visitor has completed the visit of the ptree.
      # @param aParseTree [Rley::PTree::ParseTree] the visited ptree.
      def end_visit_ptree(aParseTree)
        broadcast(:after_ptree, aParseTree)
      end

      # Visit event. The visitor is about to visit a symbol node.
      # @param aSymbolNode [Notation::SymbolNode] the symbol node to visit
      def visit_symbol_node(aSymbolNode)
        broadcast(:before_symbol_node, aSymbolNode, self)
        broadcast(:after_symbol_node, aSymbolNode, self)
      end

      # Visit event. The visitor is about to visit a sequence node.
      # @param aSequenceNode [Notation::SequenceNode] the sequence node to visit
      def visit_sequence_node(aSequenceNode)
        broadcast(:before_sequence_node, aSequenceNode, self)
        traverse_subnodes(aSequenceNode)
        broadcast(:after_sequence_node, aSequenceNode, self)
      end

      # Visit event. The visitor is about to visit a grouping node.
      # @param aGroupingNode [Notation::GroupingNode] the grouping node to visit
      def visit_grouping_node(aGroupingNode)
        broadcast(:before_grouping_node, aGroupingNode, self)
        traverse_subnodes(aGroupingNode) if aGroupingNode.repetition == :exactly_one
        broadcast(:after_grouping_node, aGroupingNode, self)
      end

      private

      # Visit event. The visitor is about to visit the subnodes of a non
      # terminal node.
      # @param aParentNode [Ast::LocCompoundExpr] the parent node.
      def traverse_subnodes(aParentNode)
        subnodes = aParentNode.subnodes
        broadcast(:before_subnodes, aParentNode, subnodes)

        # Let's proceed with the visit of subnodes
        subnodes.each { |a_node| a_node.accept(self) }

        broadcast(:after_subnodes, aParentNode, subnodes)
      end

      # Visit event. The visitor is about to visit one given subnode of a non
      # terminal node.
      # @param aParentNode [Ast::LocCompoundExpr] the parent node.
      # @param index [integer] index of child subnode
      def traverse_given_subnode(aParentNode, index)
        subnode = aParentNode.subnodes[index]
        broadcast(:before_given_subnode, aParentNode, subnode)

        # Now, let's proceed with the visit of that subnode
        subnode.accept(self)

        broadcast(:after_given_subnode, aParentNode, subnode)
      end

      # Send a notification to all subscribers.
      # @param msg [Symbol] event to notify
      # @param args [Array] arguments of the notification.
      def broadcast(msg, *args)
        subscribers.each do |subscr|
          next unless subscr.respond_to?(msg) || subscr.respond_to?(:accept_all)

          subscr.send(msg, *args)
        end
      end
    end # class
  end # module
end # module      