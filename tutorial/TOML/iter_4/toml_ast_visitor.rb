# frozen_string_literal: true

class TOMLASTVisitor
  # Link to the top node to visit
  attr_reader(:top)

  # List of objects that subscribed to the visit event notification.
  attr_reader(:subscribers)

  # Build a visitor for the given top.
  # @param aTop [RGN::ASTNode] the parse tree to visit.
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

  # Visit event. The visitor is about to visit a table node.
  # @param aTableNode [TOMLTableNode] the node to visit
  def visit_table_node(aTableNode)
    broadcast(:before_table_node, aTableNode, self)
    traverse_subnodes(aTableNode)
    broadcast(:after_table_node, aTableNode, self)
  end

  # Visit event. The visitor is about to visit an inline table node.
  # @param aTableNode [TOMLITableNode] the node to visit
  def visit_itable_node(aTableNode)
    broadcast(:before_table_node, aTableNode, self)
    traverse_subnodes(aTableNode)
    broadcast(:after_table_node, aTableNode, self)
  end

  # Visit event. The visitor is about to visit a keyval node.
  # @param aTableNode [TOMLKeyvalNode] the node to visit
  def visit_keyval_node(aKeyvalNode)
    broadcast(:before_keyval_node, aKeyvalNode, self)
    traverse_subnodes(aKeyvalNode)
    broadcast(:after_keyval_node, aKeyvalNode, self)
  end

  # Visit event. The visitor is about to visit a keyval node.
  # @param aLiteralNode [TOMLLiteralNode] the node to visit
  def visit_literal_node(aLiteralNode)
    broadcast(:before_literal_node, aLiteralNode, self)
    aLiteralNode.value.accept(self)
    broadcast(:after_literal_node, aLiteralNode, self)
  end

  # Visit event. The visitor is about to visit an array node.
  # @param anArrayNode [TOMLArrayNode] the node to visit
  def visit_array_node(anArrayNode)
    broadcast(:before_array_node, anArrayNode, self)
    traverse_subnodes(anArrayNode)
    broadcast(:after_array_node, anArrayNode, self)
  end

  # Visit event. The visitor is about to visit a data value.
  # @param aBoolean [TOMLDatatype] the value to visit
  def visit_data_value(aTOMLDatatype)
    broadcast(:found_data_value, aTOMLDatatype, self)
  end

  # Visit event. The visitor is about to visit an unquoted key value.
  # @param anUnquotedKey [UnquotedKey] the value to visit
  def visit_unquoted_key(anUnquotedKey)
    broadcast(:found_unquoted_key, anUnquotedKey, self)
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
