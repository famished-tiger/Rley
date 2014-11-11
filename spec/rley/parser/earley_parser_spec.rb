require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/token'
# Load the class under test
require_relative '../../../lib/rley/parser/earley_parser'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes

  describe EarleyParser do
=begin
    let(:kw_true) { Syntax::VerbatimSymbol('true') }
    let(:kw_false) { Syntax::VerbatimSymbol('false') }
    let(:kw_null) { Syntax::VerbatimSymbol('null') }
    let(:number) do
      number_pattern = /[-+]?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?/
      Syntax::Literal('number', number_pattern)
    end
    let(:string) do
      string_pattern = /"([^\\"]|\\.)*"/
      Syntax::Literal('string', string_pattern)
    end
    let(:lbracket) { Syntax::VerbatimSymbol('[') }
    let(:rbracket) { Syntax::VerbatimSymbol(']') }
    let(:comma) { Syntax::VerbatimSymbol(',') }
    let(:array) { Syntax::NonTerminal('Array') }
    let(:object) { Syntax::NonTerminal('Object') }

    let(:array_prod) do
      Production.new(array, )
    end
=end

    # Grammar 1: A very simple language
    # S ::= A.
    # A ::= "a" A "c".
    # A ::= "b".
    let(:nt_S) { Syntax::NonTerminal.new('S') }
    let(:nt_A) { Syntax::NonTerminal.new('A') }
    let(:a_) { Syntax::VerbatimSymbol.new('a') }
    let(:b_)  { Syntax::VerbatimSymbol.new('b') }
    let(:c_)  { Syntax::VerbatimSymbol.new('c') }
    let(:prod_S) { Syntax::Production.new(nt_S, [nt_A]) }
    let(:prod_A1) { Syntax::Production.new(nt_A, [a_, nt_A, c_]) }
    let(:prod_A2) { Syntax::Production.new(nt_A, [b_]) }
    let(:grammar_abc) { Syntax::Grammar.new([prod_S, prod_A1, prod_A2]) }

    # Helper method that mimicks the output of a tokenizer
    # for the language specified by gramma_abc
    def grm1_tokens()
      tokens = [
        Token.new('a', a_),
        Token.new('a', a_),
        Token.new('b', b_),
        Token.new('c', c_),
        Token.new('c', c_)
      ]

      return tokens
    end


    # Grammar 2: categorical syllogisms
    # Every <A> is a <B>
    # Some <A> is a <B>
    # No <A> is a <B>
    # Some <A> is not a <B>
    # A, B : English common nouns such as 'cat' and 'animal'
    # Every A is not a B
    # No A is not a B
    # P is a B
    # P is not a B
    # P can be any English proper name such as Socrates.


    # Default instantiation rule
    subject { EarleyParser.new(grammar_abc) }

    context 'Initialization:' do
      it 'should be created with a grammar' do
        expect { EarleyParser.new(grammar_abc) }.not_to raise_error
      end

      it 'should know its grammar' do
        expect(subject.grammar).to eq(grammar_abc)
      end

      it 'should know its dotted items' do
        expect(subject.dotted_items.size).to eq(8)
      end

      it 'should have its start mapping initialized' do
        expect(subject.start_mapping.size).to eq(2)
        
        start_items_S = subject.start_mapping[nt_S]
        expect(start_items_S.size).to eq(1)
        expect(start_items_S[0].production).to eq(prod_S)
        
        start_items_A = subject.start_mapping[nt_A]
        expect(start_items_A.size).to eq(2)
        
        # Assuming that dotted_items are created in same order 
        # than production in grammar.
        expect(start_items_A[0].production).to eq(prod_A1)
        expect(start_items_A[1].production).to eq(prod_A2)
      end
      
      it 'should have its next mapping initialized' do
        expect(subject.next_mapping.size).to eq(5)
      end
    end # context

    context 'Parsing: ' do
      it 'should parse simple input' do
        parse_result = subject.parse(grm1_tokens)
        expect(parse_result.success?).to eq(true)
      end
    end # context

  end # describe

  end # module
end # module

# End of file

