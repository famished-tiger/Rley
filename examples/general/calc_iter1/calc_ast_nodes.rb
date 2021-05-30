# frozen_string_literal: true

# Classes that implement nodes of Abstract Syntax Trees (AST) representing
# calculator parse results.

CalcTerminalNode = Struct.new(:token, :value, :position) do
  def initialize(aToken, aPosition)
    self.token = aToken
    self.position = aPosition
    init_value(aToken.lexeme)
  end

  # This method can be overriden
  def init_value(aLiteral)
    self.value = aLiteral.dup
  end

  def symbol
    token.terminal
  end

  def interpret
    value
  end

  def done!
    # Do nothing
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_terminal(self)
  end
end

class CalcNumberNode < CalcTerminalNode
  def init_value(aLiteral)
    case aLiteral
      when /^[+-]?\d+$/
        self.value = aLiteral.to_i

      when /^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?$/
        self.value = aLiteral.to_f
    end
  end
end

class CalcCompositeNode
  attr_accessor(:children)
  attr_accessor(:symbol)

  def initialize(aSymbol)
    @symbol = aSymbol
    @children = []
  end

  def done!
    # Do nothing
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_nonterminal(self)
  end

  alias subnodes children
end # class

class CalcUnaryOpNode < CalcCompositeNode
  # Convert this tree node in a simpler Ruby representation.
  # Basically a Calc object corresponds to a Ruhy Hash
  def to_ruby
    rep = {}
    members.each do |pair|
      rep[pair.name.to_ruby] = pair.value.to_ruby
    end

    return rep
  end

  alias members children
end # class

class CalcNegateNode < CalcUnaryOpNode
end # class

class CalcBinaryOpNode < CalcCompositeNode
  protected

  def retrieve_operands
    operands = []
    children.each do |child|
      oper = child.respond_to?(:interpret) ? child.interpret : child
      operands << oper
    end

    return operands
  end
end # class

class CalcAddNode < CalcBinaryOpNode
  # TODO
  def interpret
    operands = retrieve_operands

    operands[0] + operands[1]
  end
end # class

class CalcSubtractNode < CalcBinaryOpNode
  # TODO
  def interpret
    operands = retrieve_operands

    operands[0] - operands[1]
  end
end # class

class CalcMultiplyNode < CalcBinaryOpNode
  # TODO
  def interpret
    operands = retrieve_operands
    operands[0] * operands[1]
  end
end # class

class CalcDivideNode < CalcBinaryOpNode
  # TODO
  def interpret
    operands = retrieve_operands
    numerator = operands[0].to_f
    denominator = operands[1]
    numerator / denominator
  end
end # class
# End of file
