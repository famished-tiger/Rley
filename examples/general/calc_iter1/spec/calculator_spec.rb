# frozen_string_literal: true

require 'rspec' # Use the RSpec framework
require_relative '../calc_lexer'
require_relative '../calc_grammar'
require_relative '../calc_ast_builder'


describe 'Calculator' do
  def expect_expr(anExpression)
    # Create a Rley facade object
    engine = Rley::Engine.new do |cfg|
      cfg.repr_builder = CalcASTBuilder
    end

    engine.use_grammar(CalcGrammar)
    raw_result = parse_expression(engine, anExpression)
    ast = engine.to_ptree(raw_result)
    return expect(ast.root.interpret)
  end

  def parse_expression(anEngine, anExpression)
    lexer = CalcLexer.new(anExpression)
    result = anEngine.parse(lexer.tokens)

    unless result.success?
      # Stop if the parse failed...
      puts "Parsing of '#{anExpression}' failed"
      puts "Reason: #{result.failure_reason.message}"
      exit(1)
    end

    return result
  end

  it 'evaluates simple number literals' do
    expect_expr('2').to eq(2)
  end

  it 'evaluates addition' do
    expect_expr('2 + 2').to eq(4)
  end

  it 'evaluates subtraction' do
    expect_expr('2.1 - 2').to be_within(0.000000000000001).of(0.1)
  end

  it 'evaluates division' do
    expect_expr('10.5 / 5').to eq(2.1)
  end

  it 'evaluates multiplication' do
    expect_expr('2 * 3.1').to eq(6.2)
  end

  it 'evaluates parentheses' do
    expect_expr('2 * (2.1 + 1)').to eq(6.2)
  end

  it 'evaluates regardless of whitespace' do
    expect_expr("2*(1+\t1)").to eq(4)
  end

  it 'evaluates order of operations' do
    expect_expr('2 * 2.1 + 1 / 2').to eq 4.7
  end

  it 'evaluates multiple levels of parentheses' do
    expect_expr('2*(1/(1+3))').to eq(0.5)
  end
end # describe
# End of file
