require 'rspec' # Use the RSpec framework
require_relative '../calc_parser' # Load the class under test
require_relative '../calc_ast_builder'

RSpec.configure do |config|
  # Display stack trace in case of failure
  config.full_backtrace = true
end


describe 'Calculator' do
  def parse_expression(anExpression)
    # Create a calculator parser object
    parser = CalcParser.new
    result = parser.parse_expression(anExpression)

    unless result.success?
      # Stop if the parse failed...
      puts "Parsing of '#{anExpression}' failed"
      puts "Reason: #{result.failure_reason.message}"
      exit(1)
    end

    return result
  end

  def print_cst(aParseResult)
    # Generate a parse tree from the parse result
    ptree = aParseResult.parse_tree

    # Let's create a parse tree visitor
    visitor = Rley::ParseTreeVisitor.new(ptree)

    # Now output formatted parse tree
    renderer = Rley::Formatter::Asciitree.new($stdout)
    renderer.render(visitor)
  end

  def build_ast(aParseResult)
    tree_builder = CalcASTBuilder
    # Generate an abstract syntax tree from the parse result
    ast = aParseResult.parse_tree(tree_builder)
    return ast.root
  end

  def expect_expr(anExpression)
    parsing = parse_expression(anExpression)
    ast = build_ast(parsing)
    return expect(ast.interpret)
  end

  context 'Parsing valid expressions' do
    it 'should evaluate simple integer literals' do
      expect_expr('2').to eq(2)
    end

    it 'should evaluate simple floating-point literals' do
      expect_expr('3.1').to eq(3.1)
    end

    it 'should evaluate positive integer literals' do
      expect_expr('+2').to eq(2)
      expect_expr('+ 2').to eq(2)
    end

    it 'should evaluate positive floating-point literals' do
      expect_expr('+3.1').to eq(3.1)
      expect_expr('+ 3.1').to eq(3.1)
    end

    it 'should evaluate negative integer literals' do
      expect_expr('-2').to eq(-2)
      expect_expr('- 2').to eq(-2)
    end

    it 'should evaluate negative floating-point literals' do
      expect_expr('-3.1').to eq(-3.1)
      expect_expr('- 3.1').to eq(-3.1)
    end

    it 'should evaluate the pi constant' do
      expect_expr('PI').to eq(3.141592653589793)
    end
    
    it 'should evaluate the negated pi constant' do
      expect_expr('-PI').to eq(-3.141592653589793)
    end    

    it "should evaluate Neper's e constant" do
      expect_expr('E').to eq(2.718281828459045)
    end
    
    it "should evaluate negated Neper's e constant" do
      expect_expr('-E').to eq(-2.718281828459045)
    end    

    it 'should evaluate integer addition' do
      expect_expr('2 + 2').to eq(4)
    end

    it 'should evaluate floating-point addition' do
      expect_expr('2.0 + 3.1').to eq(5.1)
    end

    it 'should evaluate integer subtraction' do
      expect_expr('2 - 3').to eq(-1)
    end

    it 'should evaluate floating-point subtraction' do
      expect_expr('3.1 - 2').to eq(1.1)
    end

    it 'should handle negation of negative numbers' do
       expect_expr('3--2').to eq(5)
    end

    it 'should evaluate integer multiplication' do
      expect_expr('2 * 3').to eq(6)
    end

    it 'should evaluate floating-point multiplication' do
      expect_expr('2 * 3.1').to eq(6.2)
    end

    it 'should evaluate division of integers' do
      expect_expr('5 / 2').to eq(2.5)
    end

    it 'should evaluate floating-point division' do
      expect_expr('10.5 / 5').to eq(2.1)
    end

    it 'should evaluate integer exponent' do
      expect_expr('5 ** (3 - 1)').to eq(25)
    end

    it 'should evaluate floating-point exponent' do
      expect_expr('25 ** 0.5').to eq(5)
    end

    it 'should evaluate negative exponent' do
      expect_expr('5 ** -2').to eq(0.04)
    end

    it 'should handle nested exponentiations' do
      expect_expr('2 ** 2**2)').to eq(16)
    end

    it 'should change sign of expression in parentheses' do
      expect_expr('- (2 * 5)').to eq(-10)
    end

    it 'should evaluate parentheses' do
      expect_expr('2 * (2.1 + 1)').to eq(6.2)
    end

    it 'should evaluate regardless of whitespace' do
      expect_expr("2*(1+\t1)").to eq(4)
    end

    it 'should evaluate order of operations' do
      expect_expr('2 * 2.1 + 1 / 2').to eq 4.7
    end

    it 'should evaluate multiple levels of parentheses' do
      expect_expr('2*(1/(1+3))').to eq(0.5)
    end
    
    # Some special functions
    it 'should evaluate square root of expressions' do
      expect_expr('sqrt(1 + 1)').to eq(Math.sqrt(2))
    end 

    it 'should evaluate exponential of expressions' do
      expect_expr('exp(-1)').to eq(1/Math::E)    
      expect_expr('exp(0)').to eq(1)
      expect_expr('exp(1)').to eq(Math::E)
      expect_expr('exp(2)').to be_within(0.0000000001).of(Math::E * Math::E)
    end

    it 'should evaluate natural logarithm of expressions' do
      expect_expr('ln(1/E)').to eq(-1)    
      expect_expr('ln(1)').to eq(0)    
      expect_expr('ln(E)').to eq(1)
      expect_expr('ln(E * E)').to eq(2)
    end     
 
    # Trigonometric functions
    
    it 'should compute the sinus of an expression' do
      expect_expr('sin(0)').to eq(0)
      expect_expr('sin(PI/6)').to be_within(0.0000000001).of(0.5)
      expect_expr('sin(PI/2)').to eq(1)
    end
    
    it 'should compute the cosinus of an expression' do
      expect_expr('cos(0)').to eq(1)
      expect_expr('cos(PI/3)').to be_within(0.0000000001).of(0.5)
      expect_expr('cos(PI/2)').to be_within(0.0000000001).of(0)
    end 

    it 'should compute the tangent of an expression' do
      expect_expr('tan(0)').to eq(0)
      expect_expr('tan(PI/4)').to be_within(0.0000000001).of(1)
      expect_expr('tan(5*PI/12)').to be_within(0.0000000001).of(2 + Math.sqrt(3))
    end    
 
    # Inverse trigonometric functions
    
    it 'should compute the arcsinus of an expression' do
      expect_expr('asin(0)').to eq(0)
      expect_expr('asin(0.5)').to be_within(0.0000000001).of(Math::PI/6)
      expect_expr('asin(1)').to eq(Math::PI/2)
    end
    
    it 'should compute the arccosinus of an expression' do
      expect_expr('acos(1)').to eq(0)
      expect_expr('acos(0.5)').to be_within(0.0000000001).of(Math::PI/3)
      expect_expr('acos(0)').to be_within(0.0000000001).of(Math::PI/2)
    end 

    it 'should compute the tangent of an expression' do
      expect_expr('atan(0)').to eq(0)
      expect_expr('atan(1)').to be_within(0.0000000001).of(Math::PI/4)
      expect_expr('atan(2 + sqrt(3))').to be_within(0.0000000001).of(5*Math::PI/12)
    end    
  
  end # context
end # describe
# End of file
