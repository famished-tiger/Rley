# frozen_string_literal: true

# Abstract class that generalizes a TOML key.
# An instance acts merely as a wrapper around a Ruby representation
# of the key value.
class TOMLKey
  # @return [String] the literal key
  def key
    to_key
  end
  
  # Method called from TOML to obtain the text representation of the boolean.
  # @return [String]
  def to_str
    key.to_s # Default implementation...
  end  
  
  protected
  
  def to_key
    raise NotImplementedError, 'Method to implement in subclass(es)'
  end
end # class

# Class implementing the TOML unquoted key data type.
class UnquotedKey < TOMLKey
  # Constructor. Initialize an unquoted ket from the lexeme
  def initialize(aLexeme)
    @key = validated_key(aLexeme)
  end

  protected

  def validated_key(aLexeme)
    aLexeme
  end
  
  def to_key
    @key
  end
end # class
