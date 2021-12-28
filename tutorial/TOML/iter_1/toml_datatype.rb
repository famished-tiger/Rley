# frozen_string_literal: true

# Abstract class that generalizes a value from a TOML built-in data type.
# An instance acts merely as a wrapper around a Ruby representation
# of the value.
class TOMLDatatype
  # @return [Object] The Ruby representation
  attr_reader :value

  # Constructor. Initialize a TOML value from one of its built-in data type.
  def initialize(aValue)
    @value = validated_value(aValue)
  end

  # Method called from TOML to obtain the text representation of the boolean.
  # @return [String]
  def to_str
    value.to_s # Default implementation...
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [Ast::ASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_builtin(self)
  end

  protected

  def validated_value(aValue)
    aValue
  end
end # class

# Class implementing the TOML boolean data type.
class TOMLBoolean < TOMLDatatype
end # class

# Class implementing the TOML unquoted key data type.
class UnquotedKey < TOMLDatatype
  # Method called from TOML to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class

# Class implementing the TOML string data type.
class TOMLString < TOMLDatatype
  # Method called from TOML to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class
