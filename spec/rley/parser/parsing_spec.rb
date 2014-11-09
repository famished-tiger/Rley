require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/token'
# Load the class under test
require_relative '../../../lib/rley/parser/parsing'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes

  describe Parsing do

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
    let(:start_dotted_rule) { DottedItem.new(prod_S, 0) }

    # Helper method that mimicks the output of a tokenizer
    # for the language specified by gramma_abc
    let(:grm1_tokens) do
      [
        Token.new('a', a_),
        Token.new('a', a_),
        Token.new('b', b_),
        Token.new('c', c_),
        Token.new('c', c_)
      ]
    end

    # Default instantiation rule
    subject { Parsing.new(start_dotted_rule, grm1_tokens) }

    context 'Initialization:' do

      it 'should be created with a list of tokens and a start dotted rule' do
        expect { Parsing.new(start_dotted_rule, grm1_tokens) }.not_to raise_error
      end
      
      it 'should know the input tokens' do
        expect(subject.tokens).to eq(grm1_tokens)
      end

      it 'should know its chart object' do
        expect(subject.chart).to be_kind_of(Chart)
      end

    end # context

  end # describe

  end # module
end # module

# End of file