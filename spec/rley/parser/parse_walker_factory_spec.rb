# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_walker_factory'


module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser
    describe ParseWalkerFactory do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      # Helper method use to check wether a visit event
      # matches the given expectations
      # The expectations form an array with the given elements:
      # [0] => the event symbol (:visit)
      # [1] => the parse entry being visited
      # [2] => the index of the parse entry set to which the visitee belongs to
      def event_expectations(anEvent, expectations)
        visit_event, entry, index = anEvent
        expect(visit_event).to eq(expectations[0])
        if expectations[1].is_a?(String)
          case entry
            when Parser::ParseEntry
              expect(entry.to_s).to eq(expectations[1])
            when Lexical::Token
              expect(entry.lexeme).to eq(expectations[1])
          end
        else
          expect(entry).to eq(expectations[1])
        end
        expect(index).to eq(expectations[2])
      end

      let(:sample_grammar) do
          # Grammar based on paper from Elisabeth Scott
          # "SPPF=Style Parsing From Earley Recognizers" in
          # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
          # contains a hidden left recursion and a cycle
          builder = Syntax::GrammarBuilder.new do
            add_terminals('a', 'b')
            rule'Phi' => 'S'
            rule'S' => %w[A T]
            rule'S' => %w[a T]
            rule'A' => 'a'
            rule'A' => %w[B A]
            rule'B' => []
            rule'T' => %w[b b b]
          end
          builder.grammar
      end

      let(:sample_tokens) do
        build_token_sequence(%w[a b b b], sample_grammar)
      end

      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      let(:accept_entry) { sample_result.accepting_entry }
      let(:accept_index) { sample_result.chart.last_index }
      subject { ParseWalkerFactory.new }


      context 'Initialization:' do
        it 'should be created without argument' do
          expect { ParseWalkerFactory.new }.not_to raise_error
        end
      end # context

      context 'Parse graph traversal:' do
        it 'should create an Enumerator as a walker' do
          entry = accept_entry
          index = accept_index
          expect(subject.build_walker(entry, index)).to be_kind_of(Enumerator)
        end

        it 'should return the accepting parse entry in the first place' do
          walker = subject.build_walker(accept_entry, accept_index, false)
          first_event = walker.next
          expectations = [:visit, sample_result.accepting_entry, 4]
          event_expectations(first_event, expectations)
        end

        it 'could traverse the parse graph backwards' do
          walker = subject.build_walker(accept_entry, accept_index, false)
          event1 = walker.next
          expectations = [:visit, 'Phi. | 0', 4]
          event_expectations(event1, expectations)

          event2 = walker.next
          expectations = [:visit, 'Phi => S . | 0', 4]
          event_expectations(event2, expectations)

          event3 = walker.next
          expectations = [:visit, 'S. | 0', 4]
          event_expectations(event3, expectations)

          # Backtrack created: first alternative selected
          event4 = walker.next
          expectations = [:visit, 'S => a T . | 0', 4]
          event_expectations(event4, expectations)

          event5 = walker.next
          expectations = [:visit, 'T. | 1', 4]
          event_expectations(event5, expectations)

          event6 = walker.next
          expectations = [:visit, 'T => b b b . | 1', 4]
          event_expectations(event6, expectations)

          event7 = walker.next
          expectations = [:visit, 'T => b b . b | 1', 3]
          event_expectations(event7, expectations)

          event8 = walker.next
          expectations = [:visit, 'T => b . b b | 1', 2]
          event_expectations(event8, expectations)

          event9 = walker.next
          expectations = [:visit, 'T => . b b b | 1', 1]
          event_expectations(event9, expectations)

          event10 = walker.next
          expectations = [:visit, '.T | 1', 1]
          event_expectations(event10, expectations)

          event11 = walker.next
          expectations = [:visit, 'S => a . T | 0', 1]
          event_expectations(event11, expectations)

          event12 = walker.next
          expectations = [:visit, 'S => . a T | 0', 0]
          event_expectations(event12, expectations)

          event13 = walker.next
          expectations = [:visit, '.S | 0', 0]
          event_expectations(event13, expectations)

          event14 = walker.next
          expectations = [:visit, 'Phi => . S | 0', 0]
          event_expectations(event14, expectations)

          event15 = walker.next
          expectations = [:visit, '.Phi | 0', 0]
          event_expectations(event15, expectations)

          # Backtracking is occurring
          event16 = walker.next
          expectations = [:backtrack, 'S. | 0', 4]
          event_expectations(event16, expectations)

          event17 = walker.next
          expectations = [:visit, 'S => A T . | 0', 4]
          event_expectations(event17, expectations)

          event18 = walker.next
          expectations = [:revisit, 'T. | 1', 4] # Re-visiting end vertex
          event_expectations(event18, expectations)

          # No lazy walk: don't jump directly after corresponding start vertex
          event19 = walker.next
          expectations = [:revisit, 'T => b b b . | 1', 4]
          event_expectations(event19, expectations)

          event20 = walker.next
          expectations = [:revisit, 'T => b b . b | 1', 3]
          event_expectations(event20, expectations)

          event21 = walker.next
          expectations = [:revisit, 'T => b . b b | 1', 2]
          event_expectations(event21, expectations)

          event22 = walker.next
          expectations = [:revisit, 'T => . b b b | 1', 1]
          event_expectations(event22, expectations)

          event23 = walker.next
          expectations = [:revisit, '.T | 1', 1]
          event_expectations(event23, expectations)

          # Multiple visit occurred: jump to antecedent of start entry
          event24 = walker.next
          expectations = [:visit, 'S => A . T | 0', 1]
          event_expectations(event24, expectations)

          event25 = walker.next
          expectations = [:visit, 'A. | 0', 1]
          event_expectations(event25, expectations)

          # Backtrack created: first alternative selected
          event26 = walker.next
          expectations = [:visit, 'A => a . | 0', 1]
          event_expectations(event26, expectations)

          event27 = walker.next
          expectations = [:visit, 'A => . a | 0', 0]
          event_expectations(event27, expectations)

          event28 = walker.next
          expectations = [:visit, '.A | 0', 0]
          event_expectations(event28, expectations)

          event29 = walker.next
          expectations = [:visit, 'S => . A T | 0', 0]
          event_expectations(event29, expectations)

          event30 = walker.next
          expectations = [:revisit, '.S | 0', 0]
          event_expectations(event30, expectations)

          event31 = walker.next
          expectations = [:revisit, 'Phi => . S | 0', 0]
          event_expectations(event31, expectations)

          event32 = walker.next
          expectations = [:revisit, '.Phi | 0', 0]
          event_expectations(event32, expectations)

          # Backtracking is occurring
          event33 = walker.next
          expectations = [:backtrack, 'A. | 0', 1]
          event_expectations(event33, expectations)

          event34 = walker.next
          expectations = [:visit, 'A => B A . | 0', 1]
          event_expectations(event34, expectations)

          event35 = walker.next
          expectations = [:revisit, 'A. | 0', 1] # Revisiting end vertex
          event_expectations(event35, expectations)

          # No lazy walk: don't jump directly after corresponding start vertex
          event36 = walker.next
          expectations = [:revisit, 'A => a . | 0', 1]
          event_expectations(event36, expectations)

          event37 = walker.next
          expectations = [:revisit, 'A => . a | 0', 0]
          event_expectations(event37, expectations)

          event38 = walker.next
          expectations = [:revisit, '.A | 0', 0]
          event_expectations(event38, expectations)

          event39 = walker.next
          expectations = [:visit, 'A => B . A | 0', 0]
          event_expectations(event39, expectations)

          event40 = walker.next
          expectations = [:visit, 'B. | 0', 0]
          event_expectations(event40, expectations)

          event41 = walker.next
          expectations = [:visit, 'B => . | 0', 0]
          event_expectations(event41, expectations)

          event42 = walker.next
          expectations = [:visit, '.B | 0', 0]
          event_expectations(event42, expectations)

          event43 = walker.next
          expectations = [:visit, 'A => . B A | 0', 0]
          event_expectations(event43, expectations)

          event44 = walker.next
          expectations = [:revisit, '.A | 0', 0]
          event_expectations(event44, expectations)

          event45 = walker.next
          expectations = [:revisit, 'S => . A T | 0', 0]
          event_expectations(event45, expectations)

          event46 = walker.next
          expectations = [:revisit, '.S | 0', 0]
          event_expectations(event46, expectations)

          event47 = walker.next
          expectations = [:revisit, 'Phi => . S | 0', 0]
          event_expectations(event47, expectations)

          event48 = walker.next
          expectations = [:revisit, '.Phi | 0', 0]
          event_expectations(event48, expectations)
        end


        it 'could traverse lazily the parse graph backwards' do
          walker = subject.build_walker(accept_entry, accept_index, true)

          17.times { walker.next }

          event18 = walker.next
          expectations = [:revisit, 'T. | 1', 4]
          event_expectations(event18, expectations)
          
          # Lazy walk: make start entry .T the current one
          # Multiple visit occurred: jump to antecedent of start entry
          event19 = walker.next
          expectations = [:visit, 'S => A . T | 0', 1]
          event_expectations(event19, expectations)

          event20 = walker.next
          expectations = [:visit, 'A. | 0', 1]
          event_expectations(event20, expectations)

          # Backtrack created: first alternative selected
          event21 = walker.next
          expectations = [:visit, 'A => a . | 0', 1]
          event_expectations(event21, expectations)

          event22 = walker.next
          expectations = [:visit, 'A => . a | 0', 0]
          event_expectations(event22, expectations)

          event23 = walker.next
          expectations = [:visit, '.A | 0', 0]
          event_expectations(event23, expectations)

          event24 = walker.next
          expectations = [:visit, 'S => . A T | 0', 0]
          event_expectations(event24, expectations)

          event25 = walker.next
          expectations = [:revisit, '.S | 0', 0]
          event_expectations(event25, expectations)

          event26 = walker.next
          expectations = [:revisit, 'Phi => . S | 0', 0]
          event_expectations(event26, expectations)

          event27 = walker.next
          expectations = [:revisit, '.Phi | 0', 0]
          event_expectations(event27, expectations)

          # Backtracking is occurring
          event28 = walker.next
          expectations = [:backtrack, 'A. | 0', 1]
          event_expectations(event28, expectations)

          event29 = walker.next
          expectations = [:visit, 'A => B A . | 0', 1]
          event_expectations(event29, expectations)

          event30 = walker.next
          expectations = [:revisit, 'A. | 0', 1]
          event_expectations(event30, expectations)

          event31 = walker.next
          expectations = [:visit, 'A => B . A | 0', 0]
          event_expectations(event31, expectations)

          event32 = walker.next
          expectations = [:visit, 'B. | 0', 0]
          event_expectations(event32, expectations)

          event33 = walker.next
          expectations = [:visit, 'B => . | 0', 0]
          event_expectations(event33, expectations)

          event34 = walker.next
          expectations = [:visit, '.B | 0', 0]
          event_expectations(event34, expectations)

          event35 = walker.next
          expectations = [:visit, 'A => . B A | 0', 0]
          event_expectations(event35, expectations)

          event36 = walker.next
          expectations = [:revisit, '.A | 0', 0]
          event_expectations(event36, expectations)

          event37 = walker.next
          expectations = [:revisit, 'S => . A T | 0', 0]
          event_expectations(event37, expectations)

          event38 = walker.next
          expectations = [:revisit, '.S | 0', 0]
          event_expectations(event38, expectations)

          event39 = walker.next
          expectations = [:revisit, 'Phi => . S | 0', 0]
          event_expectations(event39, expectations)

          event40 = walker.next
          expectations = [:revisit, '.Phi | 0', 0]
          event_expectations(event40, expectations)
        end

        it 'should raise an exception at end of visit' do
          walker = subject.build_walker(accept_entry, accept_index, true)
          40.times { walker.next }

          expect { walker.next }.to raise_error(StopIteration)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
