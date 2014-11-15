require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/grammar_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe GrammarBuilder do

      context 'Initialization:' do
        it 'should be created without argument' do
          expect { GrammarBuilder.new }.not_to raise_error
        end
        
        it 'should have no grammar symbols at start' do
            expect(subject.symbols).to be_empty
        end

        it 'should have no productions at start' do
            expect(subject.productions).to be_empty
        end

      end # context

      context 'Adding symbols:' do
        it 'should build terminals from their names' do
          subject.add_terminals('a', 'b', 'c')
          expect(subject.symbols.size).to eq(3)
          expect(subject.symbols['a']).to be_kind_of(Terminal)
          expect(subject.symbols['a'].name).to eq('a')
          expect(subject.symbols['b']).to be_kind_of(Terminal)
          expect(subject.symbols['b'].name).to eq('b')
          expect(subject.symbols['c']).to be_kind_of(Terminal)
          expect(subject.symbols['c'].name).to eq('c')
        end

        it 'should accept already built terminals' do
          a = Terminal.new('a')
          b = VerbatimSymbol.new('b')
          c = Literal.new('c', /c/)

          subject.add_terminals(a, b, c)
          expect(subject.symbols.size).to eq(3)
          expect(subject.symbols['a']).to eq(a)
          expect(subject.symbols['b']).to eq(b)
          expect(subject.symbols['c']).to eq(c)
        end
        
        it 'should build non-terminals from their names' do
          subject.add_non_terminals('PP', 'VP', 'DT')
          expect(subject.symbols.size).to eq(3)
          expect(subject.symbols['PP']).to be_kind_of(NonTerminal)
          expect(subject.symbols['PP'].name).to eq('PP')
          expect(subject.symbols['VP']).to be_kind_of(NonTerminal)
          expect(subject.symbols['VP'].name).to eq('VP')
          expect(subject.symbols['DT']).to be_kind_of(NonTerminal)
          expect(subject.symbols['DT'].name).to eq('DT')
        end

        it 'should accept already built terminals' do
          a = Terminal.new('a')
          b = VerbatimSymbol.new('b')
          c = Literal.new('c', /c/)

          subject.add_terminals(a, b, c)
          expect(subject.symbols.size).to eq(3)
          expect(subject.symbols['a']).to eq(a)
          expect(subject.symbols['b']).to eq(b)
          expect(subject.symbols['c']).to eq(c)
        end
      end # context
      
      context 'Adding productions:' do
        subject do
          instance = GrammarBuilder.new
          instance.add_terminals('a', 'b', 'c')
          instance.add_non_terminals('S', 'A')
          instance
        end
        
        it 'should add a valid production' do
          # case of a rhs representation that consists of one name
          expect { subject.add_production('S' => 'A') }.not_to raise_error
          expect(subject.productions.size).to eq(1)
          new_prod = subject.productions[0]
          expect(new_prod.lhs).to eq(subject['S'])
          expect(new_prod.rhs[0]).to eq(subject['A'])
          
          subject.add_production('A' => %w(a A c))
          expect(subject.productions.size).to eq(2)
          new_prod = subject.productions.last
          expect(new_prod.lhs).to eq(subject['A'])
          expect_rhs = [ subject['a'], subject['A'], subject['c'] ]
          expect(new_prod.rhs.members).to eq(expect_rhs)
          
          subject.add_production('A' => ['b'])
          expect(subject.productions.size).to eq(3)
          new_prod = subject.productions.last
          expect(new_prod.lhs).to eq(subject['A'])
          expect(new_prod.rhs[0]).to eq(subject['b'])
        end 
      end # context
      
      context 'Building grammar:' do
        subject do
          instance = GrammarBuilder.new
          instance.add_terminals('a', 'b', 'c')
          instance.add_non_terminals('S', 'A')
          instance.add_production('S' => ['A'])
          instance.add_production('A' => %w(a A c))
          instance.add_production('A' => ['b'])
          instance
        end
        
        it 'should build a grammar' do
          expect(subject.grammar).to be_kind_of(Grammar)
          grm = subject.grammar
          expect(grm.rules).to eq(subject.productions)
        end
        
        it 'should complain in absence of symbols' do
          instance = GrammarBuilder.new
          err = StandardError
          msg = 'No symbol found for grammar'
          expect { instance.grammar }.to raise_error(err, msg)
        end
        
        it 'should complain in absence of productions' do
          instance = GrammarBuilder.new
          instance.add_terminals('a', 'b', 'c')
          instance.add_non_terminals('S', 'A')
          err = StandardError
          msg = 'No production found for grammar'
          expect { instance.grammar }.to raise_error(err, msg)
        end
      end

    end # describe
  end # module
end # module

# End of file
