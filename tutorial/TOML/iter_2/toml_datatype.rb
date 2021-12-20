# frozen_string_literal: true

# Abstract class that generalizes a value from a TOML built-in data type.
# An instance acts merely as a wrapper around a Ruby representation
# of the value.
class TOMLDatatype
  # @return [Object] The Ruby representation
  attr_reader :value

  # Constructor. Initialize a Lox value from one of its built-in data type.
  def initialize(aValue, aFormat = nil)
    @value = validated_value(aValue, aFormat)
  end

  # Method to obtain the text representation of the boolean.
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

  def validated_value(aValue, _format)
    aValue
  end
end # class

# Class implementing the TOML boolean data type.
class TOMLBoolean < TOMLDatatype
  protected

  # @param text [String] Literal value: should be 'true' or 'false'
  def validated_value(text, _format)
    text == 'true'
  end
end # class

# Class implementing the TOML integer data type.
class TOMLInteger < TOMLDatatype
  protected

  # @param text [String] Literal value: should be 'true' or 'false'
  def validated_value(text, format)
    compacted = text.gsub(/_/, '')  # Remove underscores
    case format
    when :hex
      compacted.hex
    when :oct
      compacted.oct
    when :bin
      compacted.to_i(2)
    else
      compacted.to_i
    end
  end
end # class

# Class implementing the TOML float data type.
class TOMLFloat < TOMLDatatype
  INFINITY = TOMLFloat.new(Float::INFINITY).freeze
  INFINITY_MIN = TOMLFloat.new(-Float::INFINITY).freeze
  NAN = TOMLFloat.new(Float::NAN).freeze
  NAN_MIN = TOMLFloat.new(-Float::NAN).freeze
  
  protected
  
  # @param text [String] Literal value: should be 'true' or 'false'
  def validated_value(text, format)
    compacted = text.gsub(/_/, '')  # Remove underscores
    compacted.to_f
  end  
end # class 

# Class implementing the TOML unquoted key data type.
class UnquotedKey < TOMLDatatype
  # Method to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class

# Class implementing the TOML string data type.
class TOMLString < TOMLDatatype
  # Method to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class
