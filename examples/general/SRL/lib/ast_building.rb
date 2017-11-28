# Mix-in module that provides convenenience methods for
# constructing an AST (Abstract Syntax Tree).
module ASTBuilding
  def return_first_child(_range, _tokens, theChildren)
    return theChildren[0]
  end

  def return_second_child(_range, _tokens, theChildren)
    return theChildren[1]
  end

  def return_last_child(_range, _tokens, theChildren)
    return theChildren[-1]
  end

  def return_epsilon(_range, _tokens, _children)
    return nil
  end
end # module
# End of file
