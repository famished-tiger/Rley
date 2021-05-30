# frozen_string_literal: true

module Rley # This module is used as a namespace
  # A visitor class dedicated in the visit of a parse tree.
  # It combines the Visitor and Observer patterns.
  class ParseTreeVisitor
    # Link to the parse tree to visit
    attr_reader(:ptree)

    # List of objects that subscribed to the visit event notification.
    attr_reader(:subscribers)

    # Indicates the kind of tree traversal to perform: :post_order, :pre-order
    attr_reader(:traversal)

    # Build a visitor for the given ptree.
    # @param aParseTree [ParseTree] the parse tree to visit.
    def initialize(aParseTree, aTraversalStrategy = :post_order)
      raise StandardError if aParseTree.nil?

      @ptree = aParseTree
      @subscribers = []
      @traversal = aTraversalStrategy
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

    # The signal to begin the visit of the parse tree.
    def start
      ptree.accept(self)
    end

    # Visit event. The visitor is about to visit the ptree.
    # @param aParseTree [ParseTree] the ptree to visit.
    def start_visit_ptree(aParseTree)
      broadcast(:before_ptree, aParseTree)
    end

    # Visit event. The visitor is about to visit the given non terminal node.
    # @param aNonTerminalNode [NonTerminalNode] the node to visit.
    def visit_nonterminal(aNonTerminalNode)
      if @traversal == :post_order
        broadcast(:before_non_terminal, aNonTerminalNode)
        traverse_subnodes(aNonTerminalNode)
      else
        traverse_subnodes(aNonTerminalNode)
        broadcast(:before_non_terminal, aNonTerminalNode)
      end
      broadcast(:after_non_terminal, aNonTerminalNode)
    end

    # Visit event. The visitor is visiting the
    # given terminal node.
    # @param aTerminalNode [TerminalNode] the terminal to visit.
    def visit_terminal(aTerminalNode)
      broadcast(:before_terminal, aTerminalNode)
      broadcast(:after_terminal, aTerminalNode)
    end

    # Visit event. The visitor has completed its visit of the given
    # non-terminal node.
    # @param aNonTerminalNode [NonTerminalNode] the node to visit.
    def end_visit_nonterminal(aNonTerminalNode)
      broadcast(:after_non_terminal, aNonTerminalNode)
    end

    # Visit event. The visitor has completed the visit of the ptree.
    # @param aParseTree [ParseTree] the ptree to visit.
    def end_visit_ptree(aParseTree)
      broadcast(:after_ptree, aParseTree)
    end

    private

    # Visit event. The visitor is about to visit the subnodes of a non
    # terminal node.
    # @param aParentNode [NonTeminalNode] the (non-terminal) parent node.
    def traverse_subnodes(aParentNode)
      subnodes = aParentNode.subnodes
      broadcast(:before_subnodes, aParentNode, subnodes)

      # Let's proceed with the visit of subnodes
      subnodes.each { |a_node| a_node.accept(self) }

      broadcast(:after_subnodes, aParentNode, subnodes)
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

# End of file
