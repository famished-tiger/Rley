# frozen_string_literal: true

require_relative '../iter_2/toml_key'
require_relative 'toml_datatype'

# Class implementing the TOML quoted key data type.
class QuotedKey < TOMLKey
  extend Forwardable
  def_delegators :@key, :value

  def initialize(aLexeme, aFormat)
    super(aLexeme, aFormat)
    @key = TOMLString.new(aLexeme, aFormat)
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_unquoted_key(self)
  end

  protected

  def to_key
    @key.value
  end
end # class
