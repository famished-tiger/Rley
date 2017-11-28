require_relative 'spec_helper' # Use the RSpec framework
require_relative '../lib/parser'
require_relative '../lib/ast_builder'

describe 'Integration tests:' do
  def parse(someSRL)
    parser = SRL::Parser.new
    result = parser.parse_SRL(someSRL)
  end

  def regexp_repr(aResult)
    # Generate an abstract syntax parse tree from the parse result
    regexp_expr_builder = ASTBuilder
    tree = aResult.parse_tree(regexp_expr_builder)
    regexp = tree.root
  end

  context 'Parsing quantifiers:' do
    it "should parse 'once' syntax" do
      result = parse('once')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('{1}')
    end

    it "should parse 'twice' syntax" do
      result = parse('twice')
      expect(result).to be_success
      
      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('{2}')      
    end

    it "should parse 'optional' syntax" do
      result = parse('optional')
      expect(result).to be_success
      
      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('?')      
    end

    it "should parse 'exactly ... times' syntax" do
      result = parse('exactly 4 times')
      expect(result).to be_success
      
      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('{4}')        
    end

    it "should parse 'between ... and ... times' syntax" do
      result = parse('between 2 and 4 times')
      expect(result).to be_success

      # Dropping 'times' keyword is shorter syntax
      expect(parse('between 2 and 4')).to be_success
      
      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('{2,4}')        
    end

    it "should parse 'once or more' syntax" do
      result = parse('once or more')
      expect(result).to be_success
    end

    it "should parse 'never or more' syntax" do
      result = parse('never or more')
      expect(result).to be_success
    end

    it "should parse 'at least  ... times' syntax" do
      result = parse('at least 10 times')
      expect(result).to be_success
      
      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('{10,}')      
    end

  end # context

end # describe


=begin

unless result.success?
  # Stop if the parse failed...
  puts "Parsing of '#{ARGV[0]}' failed"
  puts "Reason: #{result.failure_reason.message}"
  exit(1)
end


# Generate a concrete syntax parse tree from the parse result
cst_ptree = result.parse_tree
print_tree('Concrete Syntax Tree (CST)', cst_ptree)

# Generate an abstract syntax parse tree from the parse result
tree_builder = ASTBuilder
ast_ptree = result.parse_tree(tree_builder)
=end

