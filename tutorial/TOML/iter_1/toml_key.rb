# frozen_string_literal: true

# Abstract class that generalizes a TOML key.
# An instance acts merely as a wrapper around a Ruby representation
# of the key value.
class TOMLKey
  # Constructor. Initialize a TOML value from one of its built-in data type.
  # @param _lexeme [String] Text representation of data type in TOML.
  # @param _format [Symbol, NilClass] A symbolic name of the input format.
  def initialize(_lexeme, _format = nil)
    # Do nothing
  end

  # @return [String] the literal key
  def key
    to_key
  end

  # Method called from TOML to obtain the text representation of the key.
  # @return [String]
  def to_str
    key.to_s # Default implementation...
  end

  # Key text equality test
  # @param other [TOMLKey, String]
  # @return [Boolean]
  def ==(other)
    return true if equal?(other)

    return to_str == other if other.kind_of?(String)

    key == other.key
  end

  protected

  def to_key
    raise NotImplementedError, 'Method to implement in subclass(es)'
  end
end # class

# Class implementing the TOML unquoted key data type.
class UnquotedKey < TOMLKey
  # Constructor. Initialize an unquoted ket from the lexeme
  def initialize(aLexeme, format = nil)
    super(aLexeme, format)
    @key = validated_key(aLexeme)
  end

  alias value key

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_unquoted_key(self)
  end

  protected

  def validated_key(aLexeme)
    aLexeme
  end

  def to_key
    @key
  end
end # class
