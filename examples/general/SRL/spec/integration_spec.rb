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
  end # context

  context 'Parsing string literals:' do
    it 'should parse double quotes literal string' do
      result = parse('literally "hello"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('hello')
    end

    it 'should parse single quotes literal string' do
      result = parse("literally 'hello'")
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('hello')
    end

    it 'should escape special characters' do
      result = parse("literally '.'")
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\.')
    end
  end

  context 'Parsing character classes:' do
    it "should parse 'digit' syntax" do
      result = parse('digit')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\d')
    end

    it "should parse 'number' syntax" do
      result = parse('number')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\d')
    end

    it "should parse 'any character' syntax" do
      result = parse('any character')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\w')
    end

    it "should parse 'no character' syntax" do
      result = parse('no character')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\W')
    end

    it "should parse 'whitespace' syntax" do
      result = parse('whitespace')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\s')
    end

    it "should parse 'no whitespace' syntax" do
      result = parse('no whitespace')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\S')
    end

    it "should parse 'anything' syntax" do
      result = parse('anything')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('.')
    end

    it "should parse 'one of' syntax" do
      result = parse('one of "._%+-"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      # Remark: reference implementation less readable
      # (escapes more characters than required)
      expect(regexp.to_str).to eq('[._%+\-]')
    end
  end # context

  context 'Parsing special character declarations:' do
    it "should parse 'tab' syntax" do
      result = parse('tab')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\t')
    end

    it "should parse 'backslash' syntax" do
      result = parse('backslash')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\\')
    end

    it "should parse 'new line' syntax" do
      result = parse('new line')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\n')
    end
  end # context

  context 'Parsing alternations:' do
    it "should parse 'any of' syntax" do
      source = 'any of (any character, one of "._%-+")'
      result = parse(source)
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(?:\w|[._%\-+])')
    end
  end # context

  context 'Parsing concatenation:' do
    it "should reject dangling comma" do
      source = 'literally "a",'
      result = parse(source)
      expect(result).not_to be_success
      message_prefix = /Premature end of input after ','/
      expect(result.failure_reason.message).to match(message_prefix)
    end
    
    it 'should parse concatenation' do
      result = parse('any of (literally "sample", (digit once or more))')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(?:sample|(?:\d+))')
    end

    it "should parse a long sequence of patterns" do
      source = <<-ENDS
      any of (any character, one of "._%-+") once or more,
      literally "@",
      any of (digit, letter, one of ".-") once or more,
      literally ".",
      letter at least 2 times
ENDS

      result = parse(source)
      expect(result).to be_success

      regexp = regexp_repr(result)
      # SRL expect: (?:\w|[\._%\-\+])+(?:@)(?:[0-9]|[a-z]|[\.\-])+(?:\.)[a-z]{2,}
      expect(regexp.to_str).to eq('(?:\w|[._%\-+])+@(?:\d|[a-z]|[.\-])+\.[a-z]{2,}')
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
      result = parse('digit twice')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('\d{2}')
    end

    it "should parse 'optional' syntax" do
      result = parse('anything optional')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('.?')
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

  context 'Parsing lookaround:' do
    it 'should parse positive lookahead' do
      result = parse('letter if followed by (anything once or more, digit)')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[a-z](?=(?:.+\d))')
    end
    
    it 'should parse negative lookahead' do
      result = parse('letter if not followed by (anything once or more, digit)')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('[a-z](?!(?:.+\d))')
    end

    it 'should parse positive lookbehind' do
      result = parse('literally "bar" if already had literally "foo"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('bar(?<=foo)')
    end

    it 'should parse negative lookbehind' do
      result = parse('literally "bar" if not already had literally "foo"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('bar(?<!foo)')
    end    
  end # context
  
  context 'Parsing capturing group:' do
    it 'should parse simple anonymous capturing group' do
      result = parse('capture(literally "sample")')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(sample)')
    end  
  
    it 'should parse complex anonymous capturing group' do
      result = parse('capture(any of (literally "sample", (digit once or more)))')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('((?:sample|(?:\d+)))')
    end
    
    it 'should parse simple anonymous until capturing group' do
      result = parse('capture anything once or more until literally "!"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(.+)!')
    end

    it 'should parse complex named capturing group' do
      result = parse('capture(any of (literally "sample", (digit once or more))) as "foo"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(?<foo>(?:sample|(?:\d+)))')
    end
    
    it 'should parse a sequence with named capturing groups' do
      source = <<-ENDS
      capture (anything once or more) as "first",
      literally " - ", 
      capture literally "second part" as "second"
ENDS
      result = parse(source)
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(?<first>.+) - (?<second>second part)')
    end   

    it 'should parse complex named until capturing group' do
      result = parse('capture (anything once or more) as "foo" until literally "m"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('(?<foo>.+)m')
    end
   
  end # context

  context 'Parsing anchors:' do
    it 'should parse begin anchors' do
      result = parse('starts with literally "match"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('^match')
    end

    it 'should parse begin anchors (alternative syntax)' do
      result = parse('begin with literally "match"')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('^match')
    end

    it 'should parse end anchors' do
      result = parse('literally "match" must end')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('match$')
    end

    it 'should parse combination of begin and end anchors' do
      result = parse('starts with literally "match" must end')
      expect(result).to be_success

      regexp = regexp_repr(result)
      expect(regexp.to_str).to eq('^match$')
    end

    it "should accept anchor with a sequence of patterns" do
      source = <<-ENDS
      begin with any of (digit, letter, one of ".-") once or more,
      literally ".",
      letter at least 2 times must end
ENDS

      result = parse(source)
      expect(result).to be_success

      regexp = regexp_repr(result)
      # SRL expect: (?:\w|[\._%\-\+])+(?:@)(?:[0-9]|[a-z]|[\.\-])+(?:\.)[a-z]{2,}
      expect(regexp.to_str).to eq('^(?:\d|[a-z]|[.\-])+\.[a-z]{2,}$')
    end
  end # context
end # describe


