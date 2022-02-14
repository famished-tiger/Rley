# frozen_string_literal: true

# Abstract class that generalizes a value from a TOML built-in data type.
# An instance acts merely as a wrapper around a Ruby representation
# of the value.
class TOMLDatatype
  # @return [Object] The Ruby representation
  attr_reader :value

  # Constructor. Initialize a TOML value from one of its built-in data type.
  # @param aValue [String] Text representation of data type in TOML.
  # @param aFormant [Symbol, NilClass] A symbolic name of the input format.
  def initialize(aValue, aFormat = nil)
    @value = validated_value(aValue, aFormat)
  end

  def ==(other)
    return true if equal?(other)

    if other.kind_of?(TOMLDatatype)
      value == other.value
    else
      value == other
    end
  end

  # Method to obtain the text representation of the boolean.
  # @return [String]
  def to_str
    value.to_s # Default implementation...
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_data_value(self)
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
    compacted = text.gsub(/_/, '') # Remove underscores
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
  def validated_value(text, _format)
    compacted = text.gsub(/_/, '') # Remove underscores
    compacted.to_f
  end
end # class
=begin
# Class implementing the TOML unquoted key data type.
class UnquotedKey < TOMLDatatype
  # Method to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_unquoted_key(self)
  end

  protected

  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class
=end
# Class implementing the TOML string data type.
class TOMLString < TOMLDatatype
  PATT_STRING_ESCAPE = /\\(?:[^Uu]|u[0-9A-Fa-f]{0,4}|U[0-9A-Fa-f]{0,8})/.freeze

  # Single character that have a special meaning when escaped
  # @return [{Char => String}]
  @@escape_chars = {
    ?b => "\b",
    ?f => "\f",
    ?n => "\n",
    ?r => "\r",
    ?t => "\t",
    ?" => ?",
    '\\' => '\\'
  }.freeze

  # Method to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue, format)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    (format == :basic) ? unescape(aValue) : aValue
  end

  private

  def unescape(aString)
    aString.gsub(PATT_STRING_ESCAPE) do |match|
      match.slice!(0)
      case match[0]
      when ?u
        codepoint2char(match, 4)

      when ?U
        codepoint2char(match, 8)

      else
        ch = @@escape_chars[match[0]]
        if ch.nil?
          raise ScanError, "#{error_prefix}: Reserved escape code \\#{match}."
        end

        ch
      end
    end
  end

  def codepoint2char(codepoint, length)
    if codepoint.length < length
      raise StandardError, "#{error_prefix}: escape sequence \\#{match} must have exactly #{length} hexdigits."
    end

    [codepoint[1..-1].hex].pack('U') # Ugly: conversion from codepoint to character
  end
end # class
