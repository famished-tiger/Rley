# frozen_string_literal: true

# require 'pry'
require 'prime'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Monkey-patching
    class CompositeNode
      attr_reader(:signatures)

      # Associate for each edge between this node and each subnode
      # an unique prime number (called a signature).
      def add_edge_signatures(prime_enumerator)
        @signatures = subnodes.map { |_| prime_enumerator.next }
      end

      def signature_exist?()
        @signatures.nil? ? false : true
      end
    end # class
  end # module

  # A visitor class dedicated in the visit of a parse forest.
  # It combines the Visitor and Observer patterns.
  class ParseForestVisitor
    # @return [SPPF::ParseForest] Link to the parse forest to visit
    attr_reader(:pforest)

    # @return [Array<Object>]
    #   List of objects that subscribed to the visit event notification.
    attr_reader(:subscribers)

    # @return [Enumerator]
    # Enumerator that generates a sequence of prime numbers
    attr_reader(:prime_enum)

    # @return [Array<SPPF::CompositeNode, Integer>]
    #   Stack of [node, path signature]
    # path signature: an integer value that represents the set of edges used
    # in traversal
    attr_reader(:legs)

    # @return [Hash{SPPF::CompositeNode, Array<Integer>}]
    #   Keep trace from which path(s) a given node was accessed
    attr_reader(:node_accesses)

    # Build a visitor for the given pforest.
    # @param aParseForest [SPPF::ParseForest] the parse tree to visit.
    def initialize(aParseForest)
      @pforest = aParseForest
      @subscribers = []
      @prime_enum = Prime.instance.each
      @legs = []
      @node_accesses = Hash.new { |h, key| h[key] = [] }
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
    # @param nonTerminalNd [NonTerminalNode] the node to visit.
    def visit_nonterminal(nonTerminalNd)
      broadcast(:before_non_terminal, nonTerminalNd)
      unless nonTerminalNd.signature_exist?
        nonTerminalNd.add_edge_signatures(prime_enum)
      end
      traverse_children(nonTerminalNd)
      broadcast(:after_non_terminal, nonTerminalNd)
    end

    # TODO: control the logic of this method.
    # Visit event. The visitor is visiting the
    # given alternative node.
    # @param alternativeNd [AlternativeNode] the alternative node to visit.
    def visit_alternative(alternativeNd)
      broadcast(:before_alternative, alternativeNd)
      unless alternativeNd.signature_exist?
        alternativeNd.add_edge_signatures(prime_enum)
      end

      traverse_children(alternativeNd)
      broadcast(:after_alternative, alternativeNd)
    end

    # Visit event. The visitor is visiting the
    # given terminal node.
    # @param aTerminalNode [TerminalNode] the terminal to visit.
    def visit_terminal(aTerminalNode)
      broadcast(:before_terminal, aTerminalNode)
      broadcast(:after_terminal, aTerminalNode)
    end

    # Visit event. The visitor is visiting the
    # given epsilon node.
    # @param anEpsilonNode [EpsilonNode] the terminal to visit.
    def visit_epsilon(anEpsilonNode)
      broadcast(:before_epsilon, anEpsilonNode)
      broadcast(:after_epsilon, anEpsilonNode)
    end

    # Visit event. The visitor has completed its visit of the given
    # non-terminal node.
    # @param aNonTerminalNode [NonTerminalNode] the node to visit.
    # def end_visit_nonterminal(aNonTerminalNode)
    #   broadcast(:after_non_terminal, aNonTerminalNode)
    # end

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
      broadcast(:before_subnodes, aParentNode, children)

      # Let's proceed with the visit of children
      children.each_with_index do |a_node, i|
        edge_sign = aParentNode.signatures[i]
        if a_node.kind_of?(SPPF::CompositeNode)
          push_node(a_node, edge_sign)
          access_paths = node_accesses[a_node]
          last_path = legs.last[-1]
          path_reused = access_paths.include?(last_path)
          unless path_reused
            node_accesses[a_node].push(last_path)
            a_node.accept(self)
          end
          pop_node
        else
          a_node.accept(self)
        end
      end

      broadcast(:after_subnodes, aParentNode, children)
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

    def push_node(aCompositeNode, anEdgeSignature)
      if legs.empty?
        legs << [aCompositeNode, anEdgeSignature]
      else
        path_signature = legs.last[-1]
        # binding.pry if anEdgeSignature == 37 && path_signature != 230
        if (path_signature % anEdgeSignature).zero?
          legs << [aCompositeNode, path_signature]
        else
          legs << [aCompositeNode, path_signature * anEdgeSignature]
        end
      end
    end

    def pop_node
      return if legs.empty?
      
      legs.pop
    end
  end # class
end # module
# End of file
