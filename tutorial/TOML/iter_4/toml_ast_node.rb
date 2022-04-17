# frozen_string_literal: true

# Abstract class.
# Instances of its subclasses represent nodes of an abstract syntax tree
# that is the product of the parse of an input text.
class TOMLASTNode
  # Notification that the parsing has successfully completed
  def done!
    # Default: do nothing ...
  end

  # Abstract method (must be overriden in subclasses).
  # Part of the 'visitee' role in Visitor design pattern.
  # @param _visitor [ASTVisitor] the visitor
  def accept(_visitor)
    raise NotImplementedError
  end
end # class
