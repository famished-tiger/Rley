# frozen_string_literal: true

require_relative '../../spec_helper'
require 'stringio'
require_relative '../../../lib/rley/syntax/match_closest'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/base_grammar_builder'
require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/base/dotted_item'
require_relative '../../../lib/rley/parser/gfg_parsing'

require_relative '../support/expectation_helper'

# Load the class under test
require_relative '../../../lib/rley/parser/gfg_earley_parser'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe GFGEarleyParser do
      include ExpectationHelper # Mix-in with expectation on parse entry sets
    
      Keyword = {
        'else' => 'ELSE',
        'false' => 'FALSE',
        'if' => 'IF',
        'then' => 'THEN',
        'true' => 'TRUE'
      }.freeze      
      
      def tokenizer(aTextToParse)
        scanner = StringScanner.new(aTextToParse)
        tokens = []

        loop do
          scanner.skip(/\s+/)
          break if scanner.eos?
          curr_pos = scanner.pos          
          lexeme = scanner.scan(/\S+/)        

          term_name = Keyword[lexeme]
          unless term_name
            if lexeme =~ /\d+/
              term_name = 'INTEGER'
            else 
              err_msg = "Unknown token '#{lexeme}'"
              raise StandardError,  err_msg
            end
          end
          pos = Rley::Lexical::Position.new(1, curr_pos + 1)
          tokens << Rley::Lexical::Token.new(lexeme, term_name, pos)            
        end

        tokens
      end

      let(:input) { 'if false then if true then 1 else 2' }

      context 'Ambiguous parse: ' do
        # Factory method. Creates a grammar builder for a simple grammar. 
        def grammar_if_else_amb
          builder = Rley::Syntax::BaseGrammarBuilder.new do
            add_terminals('IF', 'THEN', 'ELSE')
            add_terminals('FALSE', 'TRUE', 'INTEGER')
            
            rule 'program' => 'stmt'
            rule 'stmt' => 'IF boolean THEN stmt'
            rule 'stmt' => 'IF boolean THEN stmt ELSE stmt'
            rule 'stmt' => 'literal'
            rule 'literal' => 'boolean'
            rule 'literal' => 'INTEGER'
            rule 'boolean' => 'FALSE'
            rule 'boolean' => 'TRUE'
          end
          
          builder.grammar
        end

        subject { GFGEarleyParser.new(grammar_if_else_amb) }

        it 'should parse a valid simple input' do
          tokens = tokenizer(input)
          parse_result = subject.parse(tokens)
          expect(parse_result.success?).to eq(true)
          expect(parse_result.ambiguous?).to eq(true)
          ######################
          # Expectation chart[0]:
          expected = [
            '.program | 0',                                 # initialization
            'program => . stmt | 0',                        # start rule
            '.stmt | 0',                                    # call rule
            'stmt => . IF boolean THEN stmt | 0',           # start rule
            'stmt => . IF boolean THEN stmt ELSE stmt | 0', # start rule
            'stmt => . literal | 0',                        # start rule
            '.literal | 0',                                 # call rule
            'literal => . boolean | 0',                     # start rule
            'literal => . INTEGER | 0',                     # start rule
            '.boolean | 0',                                 # call rule
            'boolean => . FALSE | 0',                       # start rule
            'boolean => . TRUE | 0'                         # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)
          expected_terminals(parse_result.chart[0], %w[FALSE IF INTEGER TRUE])

          ######################
          # Expectation chart[1]:
          expected = [
            'stmt => IF . boolean THEN stmt | 0',           # start rule
            'stmt => IF . boolean THEN stmt ELSE stmt | 0', # start rule
            '.boolean | 1',
            'boolean => . FALSE | 1',                       # start rule
            'boolean => . TRUE | 1'                         # start rule
          ]
          result1 = parse_result.chart[1]
          expect(result1.entries.size).to eq(5)
          compare_entry_texts(result1, expected)
          expected_terminals(result1, %w[FALSE TRUE])

          ######################
          # Expectation chart[2]:
          expected = [
            'boolean => FALSE . | 1',
            'boolean. | 1',
            'stmt => IF boolean . THEN stmt | 0',
            'stmt => IF boolean . THEN stmt ELSE stmt | 0'
          ]
          result2 = parse_result.chart[2]
          expect(result2.entries.size).to eq(4)
          compare_entry_texts(result2, expected)
          expected_terminals(result2, %w[THEN])

          ######################
          # Expectation chart[3]:
          expected = [
            'stmt => IF boolean THEN . stmt | 0',
            'stmt => IF boolean THEN . stmt ELSE stmt | 0',
            '.stmt | 3',
            'stmt => . IF boolean THEN stmt | 3',
            'stmt => . IF boolean THEN stmt ELSE stmt | 3',
            'stmt => . literal | 3',
            '.literal | 3',
            'literal => . boolean | 3',
            'literal => . INTEGER | 3',
            '.boolean | 3',
            'boolean => . FALSE | 3',
            'boolean => . TRUE | 3'
          ]
          result3 = parse_result.chart[3]
          expect(result3.entries.size).to eq(12)
          compare_entry_texts(result3, expected)
          expected_terminals(result3, %w[FALSE IF INTEGER TRUE])


          ######################
          # Expectation chart[4]:
          expected = [
            'stmt => IF . boolean THEN stmt | 3',
            'stmt => IF . boolean THEN stmt ELSE stmt | 3',
            '.boolean | 4',
            'boolean => . FALSE | 4',
            'boolean => . TRUE | 4'
          ]
          result4 = parse_result.chart[4]
          expect(result4.entries.size).to eq(5)
          compare_entry_texts(result4, expected)
          expected_terminals(result4, %w[FALSE TRUE])

          ######################
          # Expectation chart[5]:
          expected = [
            'boolean => TRUE . | 4',
            'boolean. | 4',
            'stmt => IF boolean . THEN stmt | 3',
            'stmt => IF boolean . THEN stmt ELSE stmt | 3'
          ]
          result5 = parse_result.chart[5]
          expect(result5.entries.size).to eq(4)
          compare_entry_texts(result5, expected)
          expected_terminals(result5, %w[THEN])

          ######################
          # Expectation chart[6]:
          expected = [
            'stmt => IF boolean THEN . stmt | 3',
            'stmt => IF boolean THEN . stmt ELSE stmt | 3',
            '.stmt | 6',
            'stmt => . IF boolean THEN stmt | 6',
            'stmt => . IF boolean THEN stmt ELSE stmt | 6',
            'stmt => . literal | 6',
            '.literal | 6',
            'literal => . boolean | 6',
            'literal => . INTEGER | 6',
            '.boolean | 6',
            'boolean => . FALSE | 6',
            'boolean => . TRUE | 6'
          ]
          result6 = parse_result.chart[6]
          expect(result6.entries.size).to eq(12)
          compare_entry_texts(result6, expected)
          expected_terminals(result6, %w[FALSE IF INTEGER TRUE])

          ######################
          # Expectation chart[7]:
          expected = [
            'literal => INTEGER . | 6',
            'literal. | 6',
            'stmt => literal . | 6',
            'stmt. | 6',
            'stmt => IF boolean THEN stmt . | 3',
            'stmt => IF boolean THEN stmt . ELSE stmt | 3',
            'stmt. | 3',
            'stmt => IF boolean THEN stmt . | 0',
            'stmt => IF boolean THEN stmt . ELSE stmt | 0',
            'stmt. | 0',
            'program => stmt . | 0',
            'program. | 0'
          ]
          result7 = parse_result.chart[7]
          expect(result7.entries.size).to eq(12)
          compare_entry_texts(result7, expected)
          expected_terminals(result7, %w[ELSE])

          # Expectation chart[8]:
          expected = [
            'stmt => IF boolean THEN stmt ELSE . stmt | 3',
            'stmt => IF boolean THEN stmt ELSE . stmt | 0',
            '.stmt | 8',
            'stmt => . IF boolean THEN stmt | 8',
            'stmt => . IF boolean THEN stmt ELSE stmt | 8',
            'stmt => . literal | 8',
            '.literal | 8',
            'literal => . boolean | 8',
            'literal => . INTEGER | 8',
            '.boolean | 8',
            'boolean => . FALSE | 8',
            'boolean => . TRUE | 8'
          ]
          result8 = parse_result.chart[8]
          expect(result8.entries.size).to eq(12)
          compare_entry_texts(result8, expected)
          expected_terminals(result8, %w[FALSE IF INTEGER TRUE])

          ######################
          # Expectation chart[9]:
          expected = [
            'literal => INTEGER . | 8',
            'literal. | 8',
            'stmt => literal . | 8',
            'stmt. | 8',
            'stmt => IF boolean THEN stmt ELSE stmt . | 3',
            'stmt => IF boolean THEN stmt ELSE stmt . | 0',
            'stmt. | 3',
            'stmt. | 0',
            'stmt => IF boolean THEN stmt . | 0',
            'stmt => IF boolean THEN stmt . ELSE stmt | 0',
            'program => stmt . | 0',
            'program. | 0'
          ]
          result9 = parse_result.chart[9]
          expect(result9.entries.size).to eq(12)
          compare_entry_texts(result9, expected)
          expected_terminals(result9, %w[ELSE])

          ######################
          # Expectation chart[10]:
          result10 = parse_result.chart[10]
          expect(result10).to be_nil

          # The parse is ambiguous since there more than one dotted item
          # that matches the stmt. | 0 exit node on chart[9]:
          # stmt => IF boolean THEN stmt ELSE stmt . | 0'
          # stmt => IF boolean THEN stmt . | 0'
          #
          # This is related to the "dangling else problem"
        end
      end # context

      context 'Disambiguated parse: ' do
        def match_else_with_if(grammar)
          # Brittle code
          prod = grammar.rules[2]
          constraint = Syntax::MatchClosest.new(prod.rhs.members, 4, 'IF')
          prod.constraints << constraint
        end

        # Factory method. Creates a grammar builder for a simple grammar.
        def grammar_if_else
          builder = Rley::Syntax::BaseGrammarBuilder.new do
            add_terminals('IF', 'THEN', 'ELSE')
            add_terminals('FALSE', 'TRUE', 'INTEGER')

            rule 'program' => 'stmt'
            rule 'stmt' => 'IF boolean THEN stmt'

            # To prevent dangling else issue, the ELSE must match the closest preceding IF
            # rule 'stmt' => 'IF boolean THEN stmt ELSE{closest IF} stmt'
            rule 'stmt' => 'IF boolean THEN stmt ELSE stmt'
            rule 'stmt' => 'literal'
            rule 'literal' => 'boolean'
            rule 'literal' => 'INTEGER'
            rule 'boolean' => 'FALSE'
            rule 'boolean' => 'TRUE'
          end

          grm = builder.grammar
          match_else_with_if(grm)

          grm
        end

        subject { GFGEarleyParser.new(grammar_if_else) }

        it 'should cope with dangling else problem' do
          tokens = tokenizer(input)
          parse_result = subject.parse(tokens)
          expect(parse_result.success?).to eq(true)
          expect(parse_result.ambiguous?).to eq(true)
          ######################
          # Expectation chart[0]:
          expected = [
            '.program | 0',                                 # initialization
            'program => . stmt | 0',                        # start rule
            '.stmt | 0',                                    # call rule
            'stmt => . IF boolean THEN stmt | 0',           # start rule
            'stmt => . IF boolean THEN stmt ELSE stmt | 0', # start rule
            'stmt => . literal | 0',                        # start rule
            '.literal | 0',                                 # call rule
            'literal => . boolean | 0',                     # start rule
            'literal => . INTEGER | 0',                     # start rule
            '.boolean | 0',                                 # call rule
            'boolean => . FALSE | 0',                       # start rule
            'boolean => . TRUE | 0'                         # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)
          expected_terminals(parse_result.chart[0], %w[FALSE IF INTEGER TRUE])

          # The parser should work as the previous version...
          # we skip chart[2] and chart[3]
          ######################
          # Expectation chart[4]:
          expected = [
            'stmt => IF . boolean THEN stmt | 3',
            'stmt => IF . boolean THEN stmt ELSE stmt | 3',
            '.boolean | 4',
            'boolean => . FALSE | 4',
            'boolean => . TRUE | 4'
          ]
          result4 = parse_result.chart[4]
          expect(result4.entries.size).to eq(5)
          compare_entry_texts(result4, expected)
          expected_terminals(result4, %w[FALSE TRUE])

          ######################
          # Before reading ELSE
          # Expectation chart[7]:
          expected = [
            'literal => INTEGER . | 6',
            'literal. | 6',
            'stmt => literal . | 6',
            'stmt. | 6',
            'stmt => IF boolean THEN stmt . | 3',
            'stmt => IF boolean THEN stmt . ELSE stmt | 3',
            'stmt. | 3',
            'stmt => IF boolean THEN stmt . | 0',
            'stmt => IF boolean THEN stmt . ELSE stmt | 0',
            'stmt. | 0',
            'program => stmt . | 0',
            'program. | 0'
          ]
          result7 = parse_result.chart[7]
          expect(result7.entries.size).to eq(12)
          compare_entry_texts(result7, expected)
          expected_terminals(result7, %w[ELSE])

          ######################
          # After reading ELSE
          # Expectation chart[8]:
          expected = [
            'stmt => IF boolean THEN stmt ELSE . stmt | 3',
            # 'stmt => IF boolean THEN stmt ELSE . stmt | 0', # Excluded
            '.stmt | 8',
            'stmt => . IF boolean THEN stmt | 8',
            'stmt => . IF boolean THEN stmt ELSE stmt | 8',
            'stmt => . literal | 8',
            '.literal | 8',
            'literal => . boolean | 8',
            'literal => . INTEGER | 8',
            '.boolean | 8',
            'boolean => . FALSE | 8',
            'boolean => . TRUE | 8'
          ]
          result8 = parse_result.chart[8]
          found = parse_result.chart.search_entries(4, {before: 'IF'})
          expect(result8.entries.size).to eq(11)
          compare_entry_texts(result8, expected)
          expected_terminals(result8, %w[FALSE IF INTEGER TRUE])

          # How does it work?
          # ELSE was just read at position 7
          # We look backwards to nearest IF; there is one at position 3
          # In chart[8], we should exclude the dotted item:
          # 'stmt => IF boolean THEN stmt ELSE . stmt | 0'
          # Reasoning?
          # On chart[4], we find two entries for the IF .:
          # 'stmt => IF . boolean THEN stmt | 3',
          # 'stmt => IF . boolean THEN stmt ELSE stmt | 3'
          #  Only these productions that still applies at 8 must be retained
          # 'stmt => IF boolean THEN stmt ELSE . stmt | 3',
          # 'stmt => IF boolean THEN stmt ELSE . stmt | 0', # To exclude
          # Where to place the check?
          # At the dotted item?
          # call, return scan nodes
          # So if one has an annotated production rule:
          # stmt => IF boolean THEN stmt ELSE{ closest: IF }  stmt
          # then the dotted item:
          # stmt => IF boolean THEN stmt ELSE . stmt
          # should bear the constraint

          ######################
          # Expectation chart[9]:
          expected = [
            'literal => INTEGER . | 8',
            'literal. | 8',
            'stmt => literal . | 8',
            'stmt. | 8',
            'stmt => IF boolean THEN stmt ELSE stmt . | 3',
            # 'stmt => IF boolean THEN stmt ELSE stmt . | 0', # Excluded
            'stmt. | 3',
            'stmt => IF boolean THEN stmt . | 0',
            'stmt => IF boolean THEN stmt . ELSE stmt | 0',
            'stmt. | 0',
            'program => stmt . | 0',
            'program. | 0'
          ]
          result9 = parse_result.chart[9]
          expect(result9.entries.size).to eq(11)
          compare_entry_texts(result9, expected)
          expected_terminals(result9, ['ELSE'])
        end
      end # context
    end # describe
  end # module
end # module
  
      