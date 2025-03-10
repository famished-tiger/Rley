# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/rgn/grammar_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module RGN # Open this namespace to avoid module qualifier prefixes
    describe GrammarBuilder do
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

        it 'could have grammar symbols from block argument' do
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
          expect(a_builder.symbols['a']).to be_a(Syntax::Terminal)
          expect(a_builder.symbols['a'].name).to eq('a')
          expect(a_builder.symbols['b']).to be_a(Syntax::Terminal)
          expect(a_builder.symbols['b'].name).to eq('b')
          expect(a_builder.symbols['c']).to be_a(Syntax::Terminal)
          expect(a_builder.symbols['c'].name).to eq('c')
        end

        it 'accepts already built terminals' do
          a = Syntax::Terminal.new('a')
          b = Syntax::Terminal.new('b')
          c = Syntax::Terminal.new('c')

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
          # Case of a rhs representation that consists of one name only
          expect { a_builder.add_production('S' => 'A') }.not_to raise_error
          expect(a_builder.productions.size).to eq(1)
          new_prod = a_builder.productions[0]
          expect(new_prod.lhs).to eq(a_builder['S'])
          expect(new_prod.rhs[0]).not_to be_nil
          expect(new_prod.rhs[0]).to eq(a_builder['A'])

          # Case of rhs with multiple symbols
          a_builder.add_production('A' => 'a A c')
          expect(a_builder.productions.size).to eq(2)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect_rhs = [a_builder['a'], a_builder['A'], a_builder['c']]
          expect(new_prod.rhs.members).to eq(expect_rhs)

          # GrammarBuilder#rule is an alias of add_production
          a_builder.rule('A' => 'b')
          expect(a_builder.productions.size).to eq(3)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect(new_prod.rhs[0]).to eq(a_builder['b'])
        end

        it 'accepts annotated terminals' do
          a_builder.rule('A' => "a b {match_closest: 'IF' } c")
          expect(a_builder.productions.size).to eq(1)
          new_prod = a_builder.productions.last
          expect(new_prod.lhs).to eq(a_builder['A'])
          expect(new_prod.rhs[0].name).to eq('a')
          expect(new_prod.rhs[0]).to eq(a_builder['a'])
          expect(new_prod.rhs[1].name).to eq('b')
          expect(new_prod.rhs[2].name).to eq('c')
          expect(new_prod.constraints.size).to eq(1)
          expect(new_prod.constraints[0]).to be_a(Syntax::MatchClosest)
          expect(new_prod.constraints[0].idx_symbol).to eq(1) # b is on position 1
          expect(new_prod.constraints[0].closest_symb).to eq('IF')
        end

        it 'supports optional symbol' do
          instance = described_class.new
          instance.add_terminals('LPAREN', 'RPAREN')

          instance.rule 'argument_list' => 'LPAREN arguments? RPAREN'
          instance.grammar_complete!

          # implicitly called: rule('arguments_qmark' => 'arguments').tag suffix_qmark_one
          # implicitly called: rule('arguments_qmark' => '').tag suffix_qmark_none
          expect(instance.productions.size).to eq(3)
          prod_star = instance.productions.select { |prod| prod.lhs.name == 'rep_arguments_qmark' }
          expect(prod_star.size).to eq(2)
          first_prod = instance.productions.first
          expect(first_prod.lhs.name).to eq('argument_list')
          expect(first_prod.rhs.members[1].name).to eq('rep_arguments_qmark')
          expect(instance.productions.last.rhs.members).to be_empty
        end

        it "supports Kleene's star" do
          instance = described_class.new
          instance.add_terminals('EOF')

          instance.rule 'program' => 'declaration* EOF'
          instance.grammar_complete!

          # implicitly called: rule('rep_declaration_star' => 'rep_declaration_star declaration').tag suffix_star_more
          # implicitly called: rule('rep_declaration_star' => '').tag suffix_star_last
          expect(instance.productions.size).to eq(3)
          prod_star = instance.productions.select { |prod| prod.lhs.name == 'rep_declaration_star' }
          expect(prod_star.size).to eq(2)
          first_prod = instance.productions.first
          expect(first_prod.lhs.name).to eq('program')
          expect(first_prod.rhs.members[0].name).to eq('rep_declaration_star')
        end

        it "supports symbols decorated with Kleene's plus" do
          instance = described_class.new
          instance.add_terminals('plus', 'minus', 'digit')

          instance.rule 'integer' => 'value'
          instance.rule 'integer' => 'sign value'
          instance.rule 'sign' => 'plus'
          instance.rule 'sign' => 'minus'
          instance.rule 'value' => 'digit+'
          expect(instance.productions.size).to eq(5)
          instance.grammar_complete!
          expect(instance.productions.size).to eq(7)

          # implicitly called: rule('digit_plus' => 'digit_plus digit').tag suffix_plus_more
          # implicitly called: rule('digit_plus' => 'digit').tag suffix_plus_last
          expect(instance.productions.size).to eq(7) # Two additional rules generated
          prod_plus = instance.productions.select { |prod| prod.lhs.name == 'rep_digit_plus' }
          expect(prod_plus.size).to eq(2)
          val_prod = instance.productions[4]
          expect(val_prod.lhs.name).to eq('value')
          expect(val_prod.rhs.members[0].name).to eq('rep_digit_plus')
        end

        it 'supports optional grouping' do
          instance = described_class.new
          instance.add_terminals('EQUAL', 'IDENTIFIER', 'VAR')

          instance.rule 'var_decl' => 'VAR IDENTIFIER (EQUAL expression)?'
          instance.grammar_complete!

          # implicitly called: rule('seq_EQUAL_expression' => 'EQUAL expression').tag 'return_children'
          # implicitly called: rule('seq_EQUAL_expression_qmark' => 'seq_EQUAL_expression').tag suffix_qmark_one
          # implicitly called: rule('seq_EQUAL_expression_qmark' => '').tag suffix_qmark_none
          expect(instance.productions.size).to eq(3)
          first_prod = instance.productions.first
          expect(first_prod.lhs.name).to eq('var_decl')
          expect(first_prod.rhs.members[2].name).to eq('rep_seq_EQUAL_expression_qmark')
          (p1, p2) = instance.productions[1..2]
          # expect(p0.lhs.name).to eq('rep_seq_EQUAL_expression_qmark')
          # expect(p0.rhs[0].name).to eq('EQUAL')
          # expect(p0.rhs[1].name).to eq('expression')
          # expect(p0.name).to eq('return_children')

          expect(p1.lhs.name).to eq('rep_seq_EQUAL_expression_qmark')
          expect(p1.rhs[0].name).to eq('EQUAL')
          expect(p1.rhs[1].name).to eq('expression')
          # expect(p1.rhs[0].name).to eq('seq_EQUAL_expression')
          expect(p1.name).to eq('return_children') # TODO _qmark_one

          expect(p2.lhs.name).to eq('rep_seq_EQUAL_expression_qmark')
          expect(p2.rhs).to be_empty
          expect(p2.name).to eq('_qmark_none')
        end

        it 'supports grouping with star modifier' do
          instance = described_class.new
          instance.add_terminals('OR')

          instance.rule 'logic_or' => 'logic_and (OR logic_and)*'
          instance.grammar_complete!

          # implicitly called: rule('seq_OR_logic_and' => 'OR logic_and').tag 'return_children'
          # implicitly called: rule('seq_EQUAL_expression_star' => 'seq_EQUAL_expression_star seq_EQUAL_expression').tag suffix_star_more
          # implicitly called: rule('seq_EQUAL_expression_star' => '').tag suffix_star_none
          expect(instance.productions.size).to eq(4)
          first_prod = instance.productions.first
          expect(first_prod.lhs.name).to eq('logic_or')
          expect(first_prod.rhs.members[1].name).to eq('rep_seq_OR_logic_and_star')

          (p0, p1, p2) = instance.productions[1..3]
          expect(p0.lhs.name).to eq('seq_OR_logic_and')
          expect(p0.rhs[0].name).to eq('OR')
          expect(p0.rhs[1].name).to eq('logic_and')
          expect(p0.name).to eq('return_children')

          expect(p1.lhs.name).to eq('rep_seq_OR_logic_and_star')
          expect(p1.rhs[0].name).to eq('rep_seq_OR_logic_and_star')
          expect(p1.rhs[1].name).to eq('seq_OR_logic_and')
          expect(p1.name).to eq('_star_more')

          expect(p2.lhs.name).to eq('rep_seq_OR_logic_and_star')
          expect(p2.rhs).to be_empty
          expect(p2.name).to eq('_star_none')
        end

        it 'supports grouping with plus modifier' do
          instance = described_class.new
          instance.add_terminals('POINT TO SEMI_COLON')

          instance.rule 'path' => 'POINT (TO POINT)+ SEMI_COLON'
          instance.grammar_complete!

          # implicitly called: rule('seq_TO_POINT' => 'TO POINT').tag 'return_children'
          # implicitly called: rule('seq_TO_POINT_plus' => 'seq_TO_POINT_plus seq_TO_POINT').tag suffix_plus_more
          # implicitly called: rule('seq_TO_POINT_plus' => 'seq_TO_POINT').tag suffix_plus_one
          expect(instance.productions.size).to eq(4)
          first_prod = instance.productions.first
          expect(first_prod.lhs.name).to eq('path')
          expect(first_prod.rhs.members[1].name).to eq('rep_seq_TO_POINT_plus')

          (p0, p1, p2) = instance.productions[1..3]
          expect(p0.lhs.name).to eq('seq_TO_POINT')
          expect(p0.rhs[0].name).to eq('TO')
          expect(p0.rhs[1].name).to eq('POINT')
          expect(p0.name).to eq('return_children')

          expect(p1.lhs.name).to eq('rep_seq_TO_POINT_plus')
          expect(p1.rhs[0].name).to eq('rep_seq_TO_POINT_plus')
          expect(p1.rhs[1].name).to eq('seq_TO_POINT')
          expect(p1.name).to eq('_plus_more')

          expect(p2.lhs.name).to eq('rep_seq_TO_POINT_plus')
          expect(p2.rhs[0].name).to eq('seq_TO_POINT')
          expect(p2.name).to eq('_plus_one')
        end

        it 'supports grouping with nested annotation' do
          instance = described_class.new
          instance.add_terminals('IF ELSE LPAREN RPAREN')
          st = "IF LPAREN expr RPAREN stmt (ELSE { match_closest: 'IF' } stmt)?"
          instance.rule('if_stmt' => st)
          instance.grammar_complete!

          # implicitly called: rule('rep_seq_ELSE_stmt_qmark' => 'ELSE stmt').tag return_children'
          # implicitly called: rule('rep_seq_ELSE_stmt_qmark' => '').tag suffix_qmark_none
          expect(instance.productions.size).to eq(3)
          (p0, p1, p2) = instance.productions[0..2]
          expect(p0.lhs.name).to eq('if_stmt')
          expect(p0.rhs.members[5].name).to eq('rep_seq_ELSE_stmt_qmark')
          # expect(p0.lhs.name).to eq('seq_ELSE_stmt')
          # expect(p0.rhs[0].name).to eq('ELSE')
          # expect(p0.rhs[1].name).to eq('stmt')
          # expect(p0.name).to eq('return_children')
          # expect(p0.constraints.size).to eq(1)
          # expect(p0.constraints[0]).to be_a(Syntax::MatchClosest)
          # expect(p0.constraints[0].idx_symbol).to eq(0) # ELSE is on position 0
          # expect(p0.constraints[0].closest_symb).to eq('IF')

          expect(p1.lhs.name).to eq('rep_seq_ELSE_stmt_qmark')
          expect(p1.rhs[0].name).to eq('ELSE')
          expect(p1.rhs[1].name).to eq('stmt')
          expect(p1.name).to eq('return_children')
          expect(p1.constraints.size).to eq(1)
          expect(p1.constraints[0]).to be_a(Syntax::MatchClosest)
          expect(p1.constraints[0].closest_symb).to eq('IF')

          expect(p2.lhs.name).to eq('rep_seq_ELSE_stmt_qmark')
          expect(p2.rhs).to be_empty
          expect(p2.name).to eq('_qmark_none')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
