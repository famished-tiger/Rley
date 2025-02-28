# frozen_string_literal: true

require 'rspec' # Use the RSpec framework
require_relative '../calc_lexer'
require_relative '../calc_grammar'
require_relative '../calc_ast_builder'

RSpec.configure do |config|
  # Display stack trace in case of failure
  config.full_backtrace = true
end


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

  context 'Parsing valid expressions' do
    let(:epsilon) { 0.0000000001 }

    it 'evaluates simple integer literals' do
      expect_expr('2').to eq(2)
    end

    it 'evaluates simple floating-point literals' do
      expect_expr('3.1').to eq(3.1)
    end

    it 'evaluates positive integer literals' do
      expect_expr('+2').to eq(2)
      expect_expr('+ 2').to eq(2)
    end

    it 'evaluates positive floating-point literals' do
      expect_expr('+3.1').to eq(3.1)
      expect_expr('+ 3.1').to eq(3.1)
    end

    it 'evaluates negative integer literals' do
      expect_expr('-2').to eq(-2)
      expect_expr('- 2').to eq(-2)
    end

    it 'evaluates negative floating-point literals' do
      expect_expr('-3.1').to eq(-3.1)
      expect_expr('- 3.1').to eq(-3.1)
    end

    it 'evaluates the pi constant' do
      expect_expr('PI').to eq(3.141592653589793)
    end

    it 'evaluates the negated pi constant' do
      expect_expr('-PI').to eq(-3.141592653589793)
    end

    it "evaluates Neper's e constant" do
      expect_expr('E').to eq(2.718281828459045)
    end

    it "evaluates negated Neper's e constant" do
      expect_expr('-E').to eq(-2.718281828459045)
    end

    it 'evaluates integer addition' do
      expect_expr('2 + 2').to eq(4)
    end

    it 'evaluates floating-point addition' do
      expect_expr('2.0 + 3.1').to eq(5.1)
    end

    it 'evaluates integer subtraction' do
      expect_expr('2 - 3').to eq(-1)
    end

    it 'evaluates floating-point subtraction' do
      expect_expr('3.1 - 2').to eq(1.1)
    end

    it 'handles negation of negative numbers' do
       expect_expr('3--2').to eq(5)
    end

    it 'evaluates integer multiplication' do
      expect_expr('2 * 3').to eq(6)
    end

    it 'evaluates floating-point multiplication' do
      expect_expr('2 * 3.1').to eq(6.2)
    end

    it 'evaluates division of integers' do
      expect_expr('5 / 2').to eq(2.5)
    end

    it 'evaluates floating-point division' do
      expect_expr('10.5 / 5').to eq(2.1)
    end

    it 'evaluates integer exponent' do
      expect_expr('5 ** (3 - 1)').to eq(25)
    end

    it 'evaluates floating-point exponent' do
      expect_expr('25 ** 0.5').to eq(5)
    end

    it 'evaluates negative exponent' do
      expect_expr('5 ** -2').to eq(0.04)
    end

    it 'handles nested exponentiations' do
      expect_expr('2 ** 2**2').to eq(16)
    end

    it 'changes sign of expression in parentheses' do
      expect_expr('- (2 * 5)').to eq(-10)
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

    # Some special functions
    it 'evaluates square root of expressions' do
      expect_expr('sqrt(0)').to eq(0)
      expect_expr('sqrt(1)').to eq(1)
      expect_expr('sqrt(1 + 1)').to eq(Math.sqrt(2))
      expect_expr('sqrt(5 * 5)').to eq(5)
    end

    it 'evaluates cubic root of expressions' do
      expect_expr('cbrt(0)').to eq(0)
      expect_expr('cbrt(1)').to eq(1)
      expect_expr('cbrt(1 + 1)').to eq(Math.cbrt(2))
      expect_expr('cbrt(5 * 5 * 5)').to eq(5)
    end

    it 'evaluates exponential of expressions' do
      expect_expr('exp(-1)').to eq(1 / Math::E)
      expect_expr('exp(0)').to eq(1)
      expect_expr('exp(1)').to eq(Math::E)
      expect_expr('exp(2)').to be_within(epsilon).of(Math::E * Math::E)
    end

    it 'evaluates natural logarithm of expressions' do
      expect_expr('ln(1/E)').to eq(-1)
      expect_expr('ln(1)').to eq(0)
      expect_expr('ln(E)').to eq(1)
      expect_expr('ln(E * E)').to eq(2)
    end

    it 'evaluates the logarithm base 10 of expressions' do
      expect_expr('log(1/10)').to eq(-1)
      expect_expr('log(1)').to eq(0)
      expect_expr('log(10)').to eq(1)
      expect_expr('log(10 * 10 * 10)').to eq(3)
    end

    # Trigonometric functions

    it 'computes the sinus of an expression' do
      expect_expr('sin(0)').to eq(0)
      expect_expr('sin(PI/6)').to be_within(epsilon).of(0.5)
      expect_expr('sin(PI/2)').to eq(1)
    end

    it 'computes the cosinus of an expression' do
      expect_expr('cos(0)').to eq(1)
      expect_expr('cos(PI/3)').to be_within(epsilon).of(0.5)
      expect_expr('cos(PI/2)').to be_within(epsilon).of(0)
    end

    it 'computes the tangent of an expression' do
      expect_expr('tan(0)').to eq(0)
      expect_expr('tan(PI/4)').to be_within(epsilon).of(1)
      expect_expr('tan(5*PI/12)').to be_within(epsilon).of(2 + Math.sqrt(3))
    end

    # Inverse trigonometric functions

    it 'computes the arcsinus of an expression' do
      expect_expr('asin(0)').to eq(0)
      expect_expr('asin(0.5)').to be_within(epsilon).of(Math::PI / 6)
      expect_expr('asin(1)').to eq(Math::PI / 2)
    end

    it 'computes the arccosinus of an expression' do
      expect_expr('acos(1)').to eq(0)
      expect_expr('acos(0.5)').to be_within(epsilon).of(Math::PI / 3)
      expect_expr('acos(0)').to be_within(epsilon).of(Math::PI / 2)
    end

    it 'computes the arctangent of an expression' do
      expect_expr('atan(0)').to eq(0)
      pi = Math::PI
      expect_expr('atan(1)').to be_within(epsilon).of(pi / 4)
      expect_expr('atan(2 + sqrt(3))').to be_within(epsilon).of(5 * pi / 12)
    end
  end # context
end # describe
# End of file
