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

  def symbol()
    token.terminal
  end

  def interpret()
    return value
  end
  
  def done!()
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
  
  # Overriding the unary minus operator
  def -@()
    self.value = - value
    return self
  end
end

class CalcConstantNode < CalcNumberNode
  @@constants2val = {
    'PI' => Math::PI,
    'E' => Math::E
  }

  def init_value(aConstantName)
    self.value = @@constants2val[aConstantName]
  end
end

class CalcReservedNode < CalcTerminalNode
end

class CalcCompositeNode
  attr_accessor(:children)
  attr_accessor(:symbol)
  attr_accessor(:position)

  def initialize(aSymbol, aPosition)
    @symbol = aSymbol
    @children = []
    @position = aPosition
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_nonterminal(self)
  end
  
  def done!()
    # Do nothing
  end

  alias subnodes children
end # class

class CalcUnaryOpNode < CalcCompositeNode
  def initialize(aSymbol, aPosition)
    super(aSymbol, aPosition)
  end

  alias members children
end # class

class CalcNegateNode < CalcUnaryOpNode  
  def interpret()
    return -children[0].interpret
  end
end # class

class CalcUnaryFunction < CalcCompositeNode
  @@name_mapping = begin 
    map = Hash.new { |me, key| me[key] = key }
    map['ln'] = 'log'
    map['log'] = 'log10'
    map
  end
  attr_accessor(:func_name)
  
  
  def interpret()
    argument = children[0].interpret
    internal_name = @@name_mapping[@func_name]
    return Math.send(internal_name.to_sym, argument)
  end  
end

class CalcBinaryOpNode < CalcCompositeNode
  def initialize(aSymbol, aRange)
    super(aSymbol, aRange)
  end

  protected

  def retrieve_operands()
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
  def interpret()
    operands = retrieve_operands

    sum = operands[0] + operands[1]
    return sum
  end
end # class


class CalcSubtractNode < CalcBinaryOpNode
  # TODO
  def interpret()
    operands = retrieve_operands

    substraction = operands[0] - operands[1]
    return substraction
  end
end # class

class CalcMultiplyNode < CalcBinaryOpNode
  # TODO
  def interpret()
    operands = retrieve_operands
    multiplication = operands[0] * operands[1]
    return multiplication
  end
end # class

class CalcDivideNode < CalcBinaryOpNode
  # TODO
  def interpret()
    operands = retrieve_operands
    numerator = operands[0].to_f
    denominator = operands[1]
    division =  numerator / denominator
    return division
  end
end # class


class PowerNode < CalcBinaryOpNode
  # TODO
  def interpret()
    operands = retrieve_operands
    exponentiation = operands[0]**operands[1]
    return exponentiation
  end
end # class
# End of file
