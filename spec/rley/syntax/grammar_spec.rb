# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/verbatim_symbol'
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
        symbols.each { |symb| result[symb] = VerbatimSymbol.new(symb) }
        result
      end

      # Grammar 1: arithmetical expressions with integers
      let(:grm1_ops) do
        operators = %w[+ - * / ( )]
        build_verbatim_symbols(operators)
      end

      # Grammar symbols for integer arithmetic expressions
      let(:number) { Literal.new('number', /\d+/) } # Positive integers only
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
      let(:a_) { VerbatimSymbol.new('a') }
      let(:b_)  { VerbatimSymbol.new('b') }
      let(:c_)  { VerbatimSymbol.new('c') }
      let(:prod_S) { Production.new(nt_S, [nt_A]) }
      let(:prod_A1) { Production.new(nt_A, [a_, nt_A, c_]) }
      let(:prod_A2) { Production.new(nt_A, [b_]) }
      let(:prod_A3) { Production.new(nt_A, [c_, nt_C]) }

=begin
      # Non-terminals that specify the lexicon of the language
      let(:noun) { NonTerminal.new('Noun') }
      let(:noun_list) { %w(flights breeze trip morning) }
      let(:verb) { NonTerminal.new('Verb') }
      let(:verb_list) { %w(is prefer like need want fly) }
      let(:adjective) { NonTerminal.new('Adjective') }
      let(:adjective_list) { %w(cheapest non-stop first latest other direct) }
      let(:pronoun) { NonTerminal.new('Pronoun') }
      let(:pronoun_list) { %w(me I you it) }
      let(:proper_noun) { NonTerminal.new('Proper_noun') }
      let(:proper_noun_list) do [ 'Alaska', 'Baltimore', 'Los Angeles',
        'Chicago', 'United', 'American' ]
      end
      let(:determiner) { NonTerminal.new('Determiner') }
      let(:determiner_list) { %w(the a an this these that) }
      let(:preposition) { NonTerminal.new('Preposition') }
      let(:preposition_list) { %w(from to on near) }
      let(:conjunction) { NonTerminal.new('Conjunction') }
      let(:conjunction_list) { %w(and or but) }




      let(:noun_prods) { prods_for_list(noun, noun_list) }
      let(:verb_prods) { prods_for_list(verb, verb_list) }
      let(:adjective_prods) { prods_for_list(adjective, adjective_list) }
      let(:pronoun_prods) { prods_for_list(pronoun, pronoun_list) }
      let(:proper_pronoun_prods) do
        prods_for_list(proper_pronoun, proper_pronoun_list)
      end
      let(:determiner_prods) { prods_for_list(determiner, determiner_list) }
      let(:preposition_prods) { prods_for_list(preposition, preposition_list) }
      let(:conjunction_prods) { prods_for_list(conjunction, conjunction_list) }

      # Productions for the L0 language (from Jurafki & Martin)
      let(:nominal_prods) { Production}
=end

      subject do
        productions = [prod_S, prod_A1, prod_A2]
        Grammar.new(productions)
      end

      context 'Initialization:' do
        it 'should be created with a list of productions' do
          expect { Grammar.new([prod_S, prod_A1, prod_A2]) }.not_to raise_error
        end

        it 'should know its productions' do
          expect(subject.rules).to eq([prod_S, prod_A1, prod_A2])
        end

        it 'should know its start symbol' do
          expect(subject.start_symbol).to eq(nt_S)
        end

        it 'should know all its symbols' do
          expect(subject.symbols).to eq([nt_S, nt_A, a_, c_, b_])
        end

        it 'should know all its non-terminal symbols' do
          expect(subject.non_terminals).to eq([nt_S, nt_A])
        end

        it 'should know its start production' do
          expect(subject.start_production).to eq(prod_S)
        end
      end # context

      context 'Provided services:' do
        it 'should retrieve its symbols from their name' do
          expect(subject.name2symbol['S']).to eq(nt_S)
          expect(subject.name2symbol['A']).to eq(nt_A)
          expect(subject.name2symbol['a']).to eq(a_)
          expect(subject.name2symbol['b']).to eq(b_)
          expect(subject.name2symbol['c']).to eq(c_)
        end

        it 'should ensure that each production has a name' do
          subject.rules.each do |prod|
            expect(prod.name).to match(Regexp.new("#{prod.lhs.name}_\\d$"))
          end
        end
      end # context

      context 'Grammar diagnosis:' do
        it 'should mark any non-terminal that has no production' do
          # S ::= A.
          # S ::= B.
          # A ::= "a" .
          # B ::=  C "b". # C doesn't appear on lhs of a rule
          prod_S1 = Rley::Syntax::Production.new(nt_S, [nt_A])
          prod_S2 = Rley::Syntax::Production.new(nt_S, [nt_B])
          prod_A = Rley::Syntax::Production.new(nt_A, [a_])
          prod_B = Rley::Syntax::Production.new(nt_B, [nt_C, b_]) # C undefined
          instance = Grammar.new([prod_S1, prod_S2, prod_A, prod_B])
          undefineds = instance.non_terminals.select(&:undefined?)
          expect(undefineds.size).to eq(1)
          expect(undefineds.first).to eq(nt_C)
        end

        it 'should mark any non-terminal as generative or not' do
          # S ::= A.
          # S ::= B.
          # A ::= "a" .
          # B ::=  C "b". # C doesn't appear on lhs of a rule
          prod_S1 = Rley::Syntax::Production.new(nt_S, [nt_A])
          prod_S2 = Rley::Syntax::Production.new(nt_S, [nt_B])
          prod_A = Rley::Syntax::Production.new(nt_A, [a_])
          prod_B = Rley::Syntax::Production.new(nt_B, [nt_C, b_]) # C undefined
          instance = Grammar.new([prod_S1, prod_S2, prod_A, prod_B])
          partitioning = instance.non_terminals.partition(&:generative?)
          expect(partitioning[0].size).to eq(2)
          expect(partitioning[0]).to eq([nt_S, nt_A])
          expect(partitioning[1]).to eq([nt_B, nt_C])
        end

        it "should do a diagnosis even for 'loopy' grammars" do
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
          instance = Grammar.new([prd_S1, prd_S2, prd_A, prd_B, prd_C, prd_D])
          partitioning = instance.non_terminals.partition(&:generative?)
          expect(partitioning[0].size).to eq(2)
          expect(partitioning[0]).to eq([nt_S, nt_A])
          expect(partitioning[1]).to eq([nt_B, nt_C, nt_D])

          undefined = instance.non_terminals.select(&:undefined?)
          expect(undefined).to be_empty
        end
      end # context

      context 'Non-nullable grammar:' do
        it 'should mark all its nonterminals as non-nullable' do
          nonterms = subject.non_terminals
          nonterms.each do |nterm|
            expect(nterm).not_to be_nullable
          end
        end
      end # context

      context 'Nullable grammars:' do
        subject do
          prod_A4 = Production.new(nt_A, [])
          productions = [prod_S, prod_A1, prod_A2, prod_A4]
          Grammar.new(productions)
        end

        it 'should mark its nullable nonterminals' do
          # In the default grammar, all nonterminals are nullable
          nonterms = subject.non_terminals
          nonterms.each do |nterm|
            expect(nterm).to be_nullable
          end
        end

        it 'should mark its nullable productions' do
          # Given the above productions, here are our expectations:
          expectations = [true, false, false, true]
          actuals = subject.rules.map(&:nullable?)
          expect(actuals).to eq(expectations)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
