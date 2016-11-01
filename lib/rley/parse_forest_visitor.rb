module Rley # This module is used as a namespace
  # A visitor class dedicated in the visit of a parse forest.
  # It combines the Visitor and Observer patterns.
  class ParseForestVisitor
    # Link to the parse forest to visit
    attr_reader(:pforest)

    # List of objects that subscribed to the visit event notification.
    attr_reader(:subscribers)

    # A Hash with pairs of the form: Node => node visit data
    attr_reader(:agenda)

    # Indicates the kind of forest traversal to perform: :post_order, :pre-order
    attr_reader(:traversal)

    # Build a visitor for the given pforest.
    # @param aParseForest [ParseForest] the parse tree to visit.
    def initialize(aParseForest, aTraversalStrategy = :post_order)
      @pforest = aParseForest
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

    # The signal to begin the visit of the parse forest.
    def start()
      pforest.accept(self)
    end


    # Visit event. The visitor is about to visit the pforest.
    # @param aParseForest [ParseForest] the pforest to visit.
    def start_visit_pforest(aParseForest)
      broadcast(:before_pforest, aParseForest)
    end


    # Visit event. The visitor is about to visit the given non terminal node.
    # @param aNonTerminalNode [NonTerminalNode] the node to visit.
    def visit_nonterminal(aNonTerminalNode)
      if @traversal == :post_order
        broadcast(:before_non_terminal, aNonTerminalNode)
        traverse_children(aNonTerminalNode)
      else
        traverse_children(aNonTerminalNode)
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

    # Visit event. The visitor has completed the visit of the pforest.
    # @param aParseForest [ParseForest] the pforest to visit.
    def end_visit_pforest(aParseForest)
      broadcast(:after_pforest, aParseForest)
    end

    private

    # Visit event. The visitor is about to visit the children of a non
    # terminal node.
    # @param aParentNode [NonTeminalNode] the (non-terminal) parent node.
    def traverse_children(aParentNode)
      children = aParentNode.children
      broadcast(:before_children, aParentNode, children)

      # Let's proceed with the visit of children
      children.each { |a_node| a_node.accept(self) }

      broadcast(:after_children, aParentNode, children)
    end

    # Send a notification to all subscribers.
    # @param msg [Symbol] event to notify
    # @param args [Array] arguments of the notification.
    def broadcast(msg, *args)
      subscribers.each do |a_subscriber|
        next unless a_subscriber.respond_to?(msg)
        a_subscriber.send(msg, *args)
      end
    end
  end # class
end # module

# End of file
