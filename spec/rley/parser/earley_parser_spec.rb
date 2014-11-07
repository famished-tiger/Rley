require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
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

    # Grammar 2: A very simple language
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
    end # context
    
  end # describe

  end # module
end # module

# End of file

  