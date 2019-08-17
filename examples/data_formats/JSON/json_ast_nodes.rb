# frozen_string_literal: true

# Classes that implement nodes of Abstract Syntax Trees (AST) representing
# JSON parse results.


JSONTerminalNode = Struct.new(:token, :value, :position) do
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

  def to_ruby()
    value
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_terminal(self)
  end
  
  def done!
    # Do nothing  
  end
end


class JSONNullNode < JSONTerminalNode
  def init_value(_aLiteral)
    self.value = nil
  end
end

class JSONBooleanNode < JSONTerminalNode
  def init_value(aLiteral)
    self.value = aLiteral == 'true'
  end
end

class JSONStringNode < JSONTerminalNode
end

class JSONNumberNode < JSONTerminalNode
  def init_value(aLiteral)
    case aLiteral
      when /^[+-]?\d+$/
        self.value = aLiteral.to_i

      when /^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?$/
        self.value = aLiteral.to_f
    end
  end
end

class JSONCompositeNode
  attr_accessor(:children)
  attr_accessor(:symbol)

  def initialize(aSymbol)
    @symbol = aSymbol
    @children = []
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_nonterminal(self)
  end
  
  def done!
    # Do nothing  
  end

  alias subnodes children
end # class


class JSONArrayNode < JSONCompositeNode
  def initialize(aSymbol)
    super(aSymbol)
  end

  # Convert this tree node in a simpler Ruby representation.
  # Basically a JSON object corresponds to a Ruhy Hash
  def to_ruby()
    rep = []
    children.each do |child|
      rep << child.to_ruby
    end

    return rep
  end
end # class

class JSONPair
  attr_reader(:name)
  attr_reader(:value)
  attr_accessor(:symbol)

  def initialize(aName, aValue, aSymbol)
    @name = aName
    @value = aValue
    @symbol = aSymbol
  end

  def children()
    return [name, value]
  end

  alias subnodes children

  # Part of the 'visitee' role in Visitor design pattern.
  # @param aVisitor[ParseTreeVisitor] the visitor
  def accept(aVisitor)
    aVisitor.visit_nonterminal(self)
  end
  
  def done!
    # Do nothing
  end
  
  def to_ruby
    rep = {}
    rep[name.to_ruby] = value.to_ruby

    return rep    
  end
end # class

class JSONObjectNode < JSONCompositeNode
  def initialize(aSymbol)
    super(aSymbol)
  end

  # Convert this tree node in a simpler Ruby representation.
  # Basically a JSON object corresponds to a Ruby Hash
  def to_ruby()
    rep = {}
    members.each do |pair|
      rep[pair.name.to_ruby] = pair.value.to_ruby
    end

    return rep
  end

  alias members children
end # class
# End of file
