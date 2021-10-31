# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/rgn/tokenizer'

module Rley # Open this namespace to avoid module qualifier prefixes
  module RGN # Open this namespace to avoid module qualifier prefixes
    describe Tokenizer do
      # Utility method for comparing actual and expected token
      # sequence. The final EOF is removed from the input sequence.
      def match_expectations(aScanner, theExpectations)
        tokens = aScanner.tokens

        tokens.each_with_index do |token, i|
          terminal, lexeme = theExpectations[i]
          expect(token.terminal).to eq(terminal)
          expect(token.lexeme).to eq(lexeme)
        end
      end

      context 'Initialization:' do
        let(:sample_text) { 'begin-object member-list end-object' }
        subject { Tokenizer.new }

        it 'could be initialized with a text to tokenize or...' do
          expect { Tokenizer.new(sample_text) }.not_to raise_error
        end

        it 'could be initialized without argument...' do
          expect { Tokenizer.new }.not_to raise_error
        end

        it 'should have its scanner initialized' do
          expect(subject.scanner).to be_kind_of(StringScanner)
        end
      end # context

      context 'Input tokenization:' do
        it 'should recognize single special character token' do
          input = '(){}?*+,'
          subject.start_with(input)
          expectations = [
            # [token lexeme]
            %w[LEFT_PAREN (],
            %w[RIGHT_PAREN )],
            %w[LEFT_BRACE {],
            %w[RIGHT_BRACE }],
            %w[QUESTION_MARK ?],
            %w[STAR *],
            %w[PLUS +],
            %w[COMMA ,]
          ]
          match_expectations(subject, expectations)
        end

        it 'should recognize one or two special character tokens' do
          input = '..'
          subject.start_with(input)
          expectations = [
            # [token lexeme]
            %w[ELLIPSIS ..]
          ]
          match_expectations(subject, expectations)
        end

        it 'should treat ? * + as symbols if they occur as suffix' do
          input = 'a+ + b* * 3 ?'
          subject.start_with(input)
          expectations = [
            # [token lexeme]
            %w[SYMBOL a],
            %w[PLUS +],
            %w[SYMBOL +],
            %w[SYMBOL b],
            %w[STAR *],
            %w[SYMBOL *],
            %w[INT_LIT 3],
            %w[SYMBOL ?]
          ]
          match_expectations(subject, expectations)
        end

        it 'should recognize annotation keywords' do
          keywords = 'match_closest: repeat:'
          subject.start_with(keywords)
          expectations = [
            # [token lexeme]
            %w[KEY match_closest],
            %w[KEY repeat]
          ]
          match_expectations(subject, expectations)
        end

        it 'should recognize ordinal integer values' do
          input = <<-RLEY_END
            3      123
            987654 0
          RLEY_END

          expectations = [
            ['3', 3],
            ['123', 123],
            ['987654', 987654],
            ['0', 0]
          ]

          subject.start_with(input)
          subject.tokens[0..-2].each_with_index do |tok, i|
            expect(tok).to be_kind_of(Rley::Lexical::Token)
            expect(tok.terminal).to eq('INT_LIT')
            (lexeme,) = expectations[i]
            expect(tok.lexeme).to eq(lexeme)
          end
        end

        it 'should recognize string literals' do
          input = <<-RLEY_END
            ""
            "string"
            "123"
            ''
            'string'
            '123'
          RLEY_END

          expectations = [
            '',
            'string',
            '123'
          ] * 2

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            expect(str.terminal).to eq('STR_LIT')
            (lexeme,) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
          end
        end

        it 'should recognize a sequence of symbols' do
          input = 'IF ifCondition statement ELSE statement'
          expectations = %w[IF ifCondition statement ELSE statement]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            expect(str.terminal).to eq('SYMBOL')
            (lexeme,) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
          end
        end

        it 'should recognize an optional symbol' do
          input = 'RETURN expression? SEMICOLON'
          expectations = [
            %w[RETURN SYMBOL],
            %w[expression SYMBOL],
            %w[? QUESTION_MARK],
            %w[SEMICOLON SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a symbol with a star quantifier' do
          input = 'declaration* EOF'
          expectations = [
            %w[declaration SYMBOL],
            %w[* STAR],
            %w[EOF SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a symbol with a plus quantifier' do
          input = 'declaration+ EOF'
          expectations = [
            %w[declaration SYMBOL],
            %w[+ PLUS],
            %w[EOF SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a grouping with a quantifier' do
          input = 'IF ifCondition statement (ELSE statement)?'
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[( LEFT_PAREN],
            %w[ELSE SYMBOL],
            %w[statement SYMBOL],
            %w[) RIGHT_PAREN],
            %w[? QUESTION_MARK]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a match closest constraint' do
          input = "IF ifCondition statement ELSE { match_closest: 'IF' } statement"
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[ELSE SYMBOL],
            %w[{ LEFT_BRACE],
            %w[match_closest KEY],
            %w[IF STR_LIT],
            %w[} RIGHT_BRACE],
            %w[statement SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a repeat constraint' do
          input = 'IF ifCondition statement { repeat: 1 }  ELSE statement'
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[{ LEFT_BRACE],
            %w[repeat KEY],
            %w[1 INT_LIT],
            %w[} RIGHT_BRACE],
            %w[ELSE SYMBOL],
            %w[statement SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a grouping with a repeat constraint' do
          input = 'IF ifCondition statement ( ELSE statement ){ repeat: 0..1 }'
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[( LEFT_PAREN],
            %w[ELSE SYMBOL],
            %w[statement SYMBOL],
            %w[) RIGHT_PAREN],
            %w[{ LEFT_BRACE],
            %w[repeat KEY],
            %w[0 INT_LIT],
            %w[.. ELLIPSIS],
            %w[1 INT_LIT],
            %w[} RIGHT_BRACE]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a combination of constraints' do
          input = "IF ifCondition statement ELSE { repeat: 1, match_closest: 'IF' } statement"
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[ELSE SYMBOL],
            %w[{ LEFT_BRACE],
            %w[repeat KEY],
            %w[1 INT_LIT],
            %w[, COMMA],
            %w[match_closest KEY],
            %w[IF STR_LIT],
            %w[} RIGHT_BRACE],
            %w[statement SYMBOL]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end

        it 'should recognize a grouping with a nested constraint' do
          input = "IF ifCondition statement ( ELSE { match_closest: 'IF' } statement ){ repeat: 0..1 }"
          expectations = [
            %w[IF SYMBOL],
            %w[ifCondition SYMBOL],
            %w[statement SYMBOL],
            %w[( LEFT_PAREN],
            %w[ELSE SYMBOL],
            %w[{ LEFT_BRACE],
            %w[match_closest KEY],
            %w[IF STR_LIT],
            %w[} RIGHT_BRACE],
            %w[statement SYMBOL],
            %w[) RIGHT_PAREN],
            %w[{ LEFT_BRACE],
            %w[repeat KEY],
            %w[0 INT_LIT],
            %w[.. ELLIPSIS],
            %w[1 INT_LIT],
            %w[} RIGHT_BRACE]
          ]

          subject.start_with(input)
          subject.tokens.each_with_index do |str, i|
            expect(str).to be_kind_of(Rley::Lexical::Token)
            (lexeme, token) = expectations[i]
            expect(str.lexeme).to eq(lexeme)
            expect(str.terminal).to eq(token)
          end
        end
      end # context
    end # describe
  end # module
end # module

# End of file
