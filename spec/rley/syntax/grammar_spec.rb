# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'

# Load the class under test
require_relative '../../../lib/rley/syntax/grammar'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe Grammar do
      # Factory method. Builds a list of productions
      # having same lhs and the symbols sequence
      # in their rhs.
      def alternate_prods(aNonTerminal, sequences)
        prods = sequences.map do |symbs|
          Production.new(aNonTerminal, symbs)
        end

        return prods
      end

      def build_verbatim_symbols(symbols)
        result = {}
        symbols.each { |symb| result[symb] = Terminal.new(symb) }
        result
      end

      subject(:a_grammar) do
        productions = [prod_S, prod_A1, prod_A2]
        described_class.new(productions)
      end

      # Grammar 1: arithmetical expressions with integers
      let(:grm1_ops) do
        operators = %w[+ - * / ( )]
        build_verbatim_symbols(operators)
      end

      # Grammar symbols for integer arithmetic expressions
      let(:number) { Terminal.new('number') } # Positive integers only
      let(:add_op) { NonTerminal.new('add_op') }
      let(:add_operators) { [grm1_ops['+'], grm1_ops['-']] }
      let(:mult_op) { NonTerminal.new('mult_op') }
      let(:mult_operators) { [grm1_ops['*'], grm1_ops['/']] }
      let(:factor) { NonTerminal.new('factor') }
      let(:term) { NonTerminal.new('term') }
      let(:expression) { NonTerminal.new('expression') }


      # Productions for grammar 1
      let(:add_op_prods) { alternate_prods(add_op, add_operators) }
      let(:mult_op_prods) { alternate_prods(mult_op, mult_operators) }
      let(:factor_prods) do
        alternatives = [
          [number],
          [grm1_ops['-'], factor],
          [grm1_ops['('], expression, grm1_ops[')']]
        ]
        alternate_prods(factor, alternatives)
      end
      let(:term_prods) do
        alternatives = [[factor], [term, mult_op, factor]]
        alternate_prods(term, alternatives)
      end
      let(:expression_prods) do
        alternatives = [[term], [expression, add_op, term]]
        alternate_prods(expression, alternatives)
      end

      # Grammar 2: A very simple language
      # S ::= A.
      # A ::= "a" A "c".
      # A ::= "b".
      let(:nt_S) { NonTerminal.new('S') }
      let(:nt_A) { NonTerminal.new('A') }
      let(:nt_B) { NonTerminal.new('B') }
      let(:nt_C) { NonTerminal.new('C') }
      let(:nt_D) { NonTerminal.new('D') }
      let(:a_) { Terminal.new('a') }
      let(:b_)  { Terminal.new('b') }
      let(:c_)  { Terminal.new('c') }
      let(:prod_S) { Production.new(nt_S, [nt_A]) }
      let(:prod_A1) { Production.new(nt_A, [a_, nt_A, c_]) }
      let(:prod_A2) { Production.new(nt_A, [b_]) }
      let(:prod_A3) { Production.new(nt_A, [c_, nt_C]) }

      context 'Initialization:' do
        it 'is created with a list of productions' do
          expect { described_class.new([prod_S, prod_A1, prod_A2]) }.not_to raise_error
        end

        it 'knows its productions' do
          expect(a_grammar.rules).to eq([prod_S, prod_A1, prod_A2])
        end

        it 'knows its start symbol' do
          expect(a_grammar.start_symbol).to eq(nt_S)
        end

        it 'knows all its symbols' do
          expect(a_grammar.symbols).to eq([nt_S, nt_A, a_, c_, b_])
        end

        it 'knows all its non-terminal symbols' do
          expect(a_grammar.non_terminals).to eq([nt_S, nt_A])
        end

        it 'knows its start production' do
          expect(a_grammar.start_production).to eq(prod_S)
        end
      end # context

      context 'Provided services:' do
        it 'retrieves its symbols from their name' do
          expect(a_grammar.name2symbol['S']).to eq(nt_S)
          expect(a_grammar.name2symbol['A']).to eq(nt_A)
          expect(a_grammar.name2symbol['a']).to eq(a_)
          expect(a_grammar.name2symbol['b']).to eq(b_)
          expect(a_grammar.name2symbol['c']).to eq(c_)
        end

        it 'ensures that each production has a name' do
          a_grammar.rules.each do |prod|
            expect(prod.name).to match(Regexp.new("#{prod.lhs.name}_\\d$"))
          end
        end
      end # context

      context 'Grammar diagnosis:' do
        it 'marks any non-terminal that has no production' do
          # S ::= A.
          # S ::= B.
          # A ::= "a" .
          # B ::=  C "b". # C doesn't appear on lhs of a rule
          prod_S1 = Rley::Syntax::Production.new(nt_S, [nt_A])
          prod_S2 = Rley::Syntax::Production.new(nt_S, [nt_B])
          prod_A = Rley::Syntax::Production.new(nt_A, [a_])
          prod_B = Rley::Syntax::Production.new(nt_B, [nt_C, b_]) # C undefined
          instance = described_class.new([prod_S1, prod_S2, prod_A, prod_B])
          undefineds = instance.non_terminals.select(&:undefined?)
          expect(undefineds.size).to eq(1)
          expect(undefineds.first).to eq(nt_C)
        end

        it 'marks any non-terminal as generative or not' do
          # S ::= A.
          # S ::= B.
          # A ::= "a" .
          # B ::=  C "b". # C doesn't appear on lhs of a rule
          prod_S1 = Rley::Syntax::Production.new(nt_S, [nt_A])
          prod_S2 = Rley::Syntax::Production.new(nt_S, [nt_B])
          prod_A = Rley::Syntax::Production.new(nt_A, [a_])
          prod_B = Rley::Syntax::Production.new(nt_B, [nt_C, b_]) # C undefined
          instance = described_class.new([prod_S1, prod_S2, prod_A, prod_B])
          partitioning = instance.non_terminals.partition(&:generative?)
          expect(partitioning[0].size).to eq(2)
          expect(partitioning[0]).to eq([nt_S, nt_A])
          expect(partitioning[1]).to eq([nt_B, nt_C])
        end

        it "does a diagnosis even for 'loopy' grammars" do
          # 'S' => 'A'
          # 'S' => 'B'
          # 'A' => 'a'
          # 'B' => 'C'
          # 'C' => 'D'
          # 'D' => 'B'
          prd_S1 = Rley::Syntax::Production.new(nt_S, [nt_A])
          prd_S2 = Rley::Syntax::Production.new(nt_S, [nt_B])
          prd_A = Rley::Syntax::Production.new(nt_A, [a_])
          prd_B = Rley::Syntax::Production.new(nt_B, [nt_C])
          prd_C = Rley::Syntax::Production.new(nt_C, [nt_D])
          prd_D = Rley::Syntax::Production.new(nt_D, [nt_B])
          instance = described_class.new([prd_S1, prd_S2, prd_A, prd_B, prd_C, prd_D])
          partitioning = instance.non_terminals.partition(&:generative?)
          expect(partitioning[0].size).to eq(2)
          expect(partitioning[0]).to eq([nt_S, nt_A])
          expect(partitioning[1]).to eq([nt_B, nt_C, nt_D])

          undefined = instance.non_terminals.select(&:undefined?)
          expect(undefined).to be_empty
        end
      end # context

      context 'Non-nullable grammar:' do
        it 'marks all its nonterminals as non-nullable' do
          nonterms = a_grammar.non_terminals
          nonterms.each do |nterm|
            expect(nterm).not_to be_nullable
          end
        end
      end # context

      context 'Nullable grammars:' do
        subject(:nullable_grammar) do
          prod_A4 = Production.new(nt_A, [])
          productions = [prod_S, prod_A1, prod_A2, prod_A4]
          described_class.new(productions)
        end

        it 'marks its nullable nonterminals' do
          # In the default grammar, all nonterminals are nullable
          nonterms = nullable_grammar.non_terminals
          expect(nonterms).to all(be_nullable)
        end

        it 'marks its nullable productions' do
          # Given the above productions, here are our expectations:
          expectations = [true, false, false, true]
          actuals = nullable_grammar.rules.map(&:nullable?)
          expect(actuals).to eq(expectations)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
