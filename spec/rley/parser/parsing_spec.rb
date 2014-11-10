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
    
    context 'Parsing:' do
      it 'should push a state to a given chart entry' do
        expect(subject.chart[1]).to be_empty
        item = DottedItem.new(prod_A1, 1)
        
        subject.push_state(item, 1, 1)
        expect(subject.chart[1]).not_to be_empty
        expect(subject.chart[1].first.dotted_rule).to eq(item)
        
        # Pushing twice the same state must be no-op
        subject.push_state(item, 1, 1)
        expect(subject.chart[1].size).to eq(1)
      end
      
      it 'should complain when trying to push a nil dotted item' do
        err = StandardError
        msg = 'Dotted item may not be nil'
        expect { subject.push_state(nil, 1, 1) }.to raise_error(err, msg)
      end
      
      
      it 'should retrieve the parse states that expect a given terminal' do
        item1 = DottedItem.new(prod_A1, 2)
        item2 = DottedItem.new(prod_A1, 1)
        subject.push_state(item1, 2, 2)
        subject.push_state(item2, 2, 2)
        states = subject.states_expecting(c_, 2)
        expect(states.size).to eq(1)
        expect(states[0].dotted_rule).to eq(item1)
      end
      
      it 'should update the states upon token match' do
        # When a input token matches an expected terminal symbol
        # then new parse states must be pushed to the following chart slot
        expect(subject.chart[1]).to be_empty
        
        item1 = DottedItem.new(prod_A1, 0)
        item2 = DottedItem.new(prod_A2, 0)
        subject.push_state(item1, 0, 0)
        subject.push_state(item2, 0, 0)
        subject.scanning(a_, 0) { |i| i } # Code block is mock
        
        # Expected side effect: a new state at chart[1]
        expect(subject.chart[1].size).to eq(1)
        new_state = subject.chart[1].states[0]
        expect(new_state.dotted_rule).to eq(item1)
        expect(new_state.origin).to eq(0)
      end
      
      # completion(aState, aPosition, &nextMapping)
    end

  end # describe

  end # module
end # module

# End of file