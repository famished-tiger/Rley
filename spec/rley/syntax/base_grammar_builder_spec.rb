# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/base_grammar_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe BaseGrammarBuilder do
      subject(:a_builder) { described_class.new }

      context 'Initialization without argument:' do
        it 'is created without argument' do
          expect { described_class.new }.not_to raise_error
        end

        it 'has no grammar symbols at start' do
            expect(a_builder.symbols).to be_empty
        end

        it 'has no productions at start' do
            expect(a_builder.productions).to be_empty
        end
      end # context

      context 'Initialization with argument:' do
        it 'is created with a block argument' do
          expect do
            described_class.new { nil }
          end.not_to raise_error
        end

        it 'has grammar symbols from block argument' do
          instance = described_class.new do
            add_terminals('a', 'b', 'c')
          end
          expect(instance.symbols.size).to eq(3)
        end

        it 'has no productions at start' do
            expect(a_builder.productions).to be_empty
        end
      end # context

      context 'Adding symbols:' do
        it 'builds terminals from their names' do
          a_builder.add_terminals('a', 'b', 'c')
          expect(a_builder.symbols.size).to eq(3)
          expect(a_builder.symbols['a']).to be_a(Terminal)
          expect(a_builder.symbols['a'].name).to eq('a')
          expect(a_builder.symbols['b']).to be_a(Terminal)
          expect(a_builder.symbols['b'].name).to eq('b')
          expect(a_builder.symbols['c']).to be_a(Terminal)
          expect(a_builder.symbols['c'].name).to eq('c')
        end

        it 'accepts already built terminals' do
          a = Terminal.new('a')
          b = Terminal.new('b')
          c = Terminal.new('c')

          a_builder.add_terminals(a, b, c)
          expect(a_builder.symbols.size).to eq(3)
          expect(a_builder.symbols['a']).to eq(a)
          expect(a_builder.symbols['b']).to eq(b)
          expect(a_builder.symbols['c']).to eq(c)
        end
      end # context

      context 'Adding productions:' do
        subject(:a_builder) do
          instance = described_class.new
          instance.add_terminals('a', 'b', 'c')
          instance
        end

        it 'adds a valid production' do
          # case of a rhs representation that consists of one name
          expect { a_builder.add_production('S' => 'A') }.not_to raise_error
          expect(a_builder.productions.size).to eq(1)
          new_prod = a_builder.productions[0]
          expect(new_prod.lhs).to eq(a_builder['S'])
          expect(new_prod.rhs[0]).to eq(a_builder['A'])

          a_builder.add_production('A' => %w[a A c])
          expect(a_builder.productions.size).to eq(2)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect_rhs = [a_builder['a'], a_builder['A'], a_builder['c']]
          expect(new_prod.rhs.members).to eq(expect_rhs)

          # Try another syntax
          a_builder.add_production('A' => 'a A c')
          expect(a_builder.productions.size).to eq(3)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect_rhs = [a_builder['a'], a_builder['A'], a_builder['c']]
          expect(new_prod.rhs.members).to eq(expect_rhs)

          # BaseGrammarBuilder#rule is an alias of add_production
          a_builder.rule('A' => ['b'])
          expect(a_builder.productions.size).to eq(4)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect(new_prod.rhs[0]).to eq(a_builder['b'])
        end

        it "supports Kleene's plus" do
          instance = described_class.new
          instance.add_terminals('plus', 'minus', 'digit')

          instance.add_production('integer' => 'value')
          instance.add_production('integer' => 'sign value')
          instance.add_production('sign' => 'plus')
          instance.add_production('sign' => 'minus')
          expect(instance.productions.size).to eq(4)
          instance.add_production('value' => 'digit+')
          expect(instance.productions.size).to eq(7) # Two additional rules generated
          prod_plus = instance.productions.select { |prod| prod.lhs.name == 'digit_plus' }
          expect(prod_plus.size).to eq(2)
          last_prod = instance.productions.last
          expect(last_prod.lhs.name).to eq('value')
          expect(last_prod.rhs.members[0].name).to eq('digit_plus')
        end
      end # context

      context 'Building grammar:' do
        subject(:a_builder) do
          instance = described_class.new do
            add_terminals('a', 'b', 'c')
            add_production('S' => ['A'])
            add_production('A' => %w[a A c])
            add_production('A' => ['b'])
          end

          instance
        end

        it 'builds a grammar' do
          expect(a_builder.grammar).to be_a(Grammar)
          grm = a_builder.grammar
          expect(grm.rules).to eq(a_builder.productions)

          # Invoking the factory method again returns
          # the same grammar object
          second_time = a_builder.grammar
          expect(second_time).to eq(grm)
        end

        it 'complains in absence of symbols' do
          instance = described_class.new
          err = StandardError
          msg = 'No symbol found for grammar'
          expect { instance.grammar }.to raise_error(err, msg)
        end

        it 'complains in absence of productions' do
          instance = described_class.new
          instance.add_terminals('a', 'b', 'c')
          err = StandardError
          msg = 'No production found for grammar'
          expect { instance.grammar }.to raise_error(err, msg)
        end

        it 'complains if one or more terminals are useless' do
          # Add one useless terminal symbol
          a_builder.add_terminals('d')

          err = StandardError
          msg = 'Useless terminal symbol(s): d.'
          expect { a_builder.grammar }.to raise_error(err, msg)

          # Add another useless terminal
          a_builder.add_terminals('e')
          msg = 'Useless terminal symbol(s): d, e.'
          expect { a_builder.grammar }.to raise_error(err, msg)
        end

        it 'builds a grammar with nullable nonterminals' do
          # Grammar 4: A grammar with nullable nonterminal
          # based on example in "Parsing Techniques" book (D. Grune, C. Jabobs)
          # S ::= E.
          # E ::= E Q F.
          # E ::= F.
          # F ::= a.
          # Q ::= *.
          # Q ::= /.
          # Q ::=.
          t_a = Terminal.new('a')
          t_star = Terminal.new('*')
          t_slash = Terminal.new('/')

          builder = described_class.new
          builder.add_terminals(t_a, t_star, t_slash)
          builder.add_production('S' => 'E')
          builder.add_production('E' => %w[E Q F])
          builder.add_production('E' => 'F')
          builder.add_production('F' => t_a)
          builder.add_production('Q' => t_star)
          builder.add_production('Q' => t_slash)
          builder.add_production('Q' => []) # Empty production

          expect { builder.grammar }.not_to raise_error
          expect(builder.productions.last).to be_empty
        end
      end # context
    end # describe
  end # module
end # module

# End of file
