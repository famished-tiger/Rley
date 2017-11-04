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
    it 'should evaluate simple number literals' do
      expect_expr('2').to eq(2)
    end
   
    it 'should evaluate positive number literals' do
      expect_expr('+2').to eq(2)
      expect_expr('+ 2').to eq(2)
    end

    it 'should evaluate negative number literals' do  
      expect_expr('-2').to eq(-2)
      expect_expr('- 2').to eq(-2)
    end  

    it 'should evaluate addition' do
      expect_expr('2 + 2').to eq(4)
    end

    it 'should evaluate subtraction' do
      expect_expr('2.1 - 2').to be_within(0.000000000000001).of(0.1)
    end

    it 'handles negative numbers' do
       expect_expr('3--2').to eq(5)
    end  
   
    it 'should evaluate division' do
      expect_expr('10.5 / 5').to eq(2.1)
    end

    it 'should evaluate multiplication' do
      expect_expr('2 * 3.1').to eq(6.2)
    end

    it 'should evaluate exponentiation' do
      expect_expr('5 ** (3 - 1)').to eq(25)
      expect_expr('25 ** 0.5').to eq(5)
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
  end # context
end # describe
# End of file
