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

  context 'Parsing character ranges:' do

    it "should parse 'letter from ... to ...' syntax" do
      result = parse('letter from a to f')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[a-f]')
    end

    it "should parse 'uppercase letter from ... to ...' syntax" do
      result = parse('UPPERCASE letter from A to F')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[A-F]')
    end

    it "should parse 'letter' syntax" do
      result = parse('letter')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[a-z]')
    end

    it "should parse 'uppercase letter' syntax" do
      result = parse('uppercase letter')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[A-Z]')
    end

    it "should parse 'digit from ... to ...' syntax" do
      result = parse('digit from 1 to 4')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[1-4]')
    end

    it "should parse 'digit' syntax" do
      result = parse('digit')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[0-9]')
    end

    it "should parse 'number' syntax" do
      result = parse('number')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[0-9]')
    end

  end # context

  context 'Parsing quantifiers:' do
    let(:prefix) { 'letter from p to t ' }

    it "should parse 'once' syntax" do
      result = parse(prefix + 'once')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]{1}')
    end

    it "should parse 'twice' syntax" do
      result = parse(prefix + 'twice')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]{2}')
    end

    it "should parse 'optional' syntax" do
      result = parse(prefix + 'optional')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]?')
    end

    it "should parse 'exactly ... times' syntax" do
      result = parse('letter from a to f exactly 4 times')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[a-f]{4}')
    end

    it "should parse 'between ... and ... times' syntax" do
      result = parse(prefix + 'between 2 and 4 times')
      expect(result).to be_success

      # Dropping 'times' keyword is shorter syntax
      expect(parse(prefix + 'between 2 and 4')).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]{2,4}')
    end


    it "should parse 'once or more' syntax" do
      result = parse(prefix + 'once or more')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]+')
    end

    it "should parse 'never or more' syntax" do
      result = parse(prefix + 'never or more')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]*')
    end

    it "should parse 'at least  ... times' syntax" do
      result = parse(prefix + 'at least 10 times')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[p-t]{10,}')
    end
  end # context
end # describe


