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
            when Parser::Token
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
          builder = Syntax::GrammarBuilder.new
          builder.add_terminals('a', 'b')
          builder.add_production('Phi' => %'S')
          builder.add_production('S' => %w[A T])
          builder.add_production('S' => %w[a T])
          builder.add_production('A' => 'a')
          builder.add_production('A' => %w[B A])
          builder.add_production('B' => [])
          builder.add_production('T' => %w( b b b))
          builder.grammar
      end

      let(:sample_tokens) do
        build_token_sequence(%w(a b b b), sample_grammar)
      end

      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      let(:subject) { ParseWalkerFactory.new }


      context 'Initialization:' do
        it 'should be created without argument' do
          expect { ParseWalkerFactory.new }.not_to raise_error
        end
      end # context

      context 'Parse graph traversal:' do
        it 'should create an Enumerator as a walker' do
          expect(subject.build_walker(sample_result)).to be_kind_of(Enumerator)
        end

        it 'should return the accepting parse entry in the first place' do
          walker = subject.build_walker(sample_result)
          first_event = walker.next
          expectations = [:visit, sample_result.accepting_entry, 4]
          event_expectations(first_event, expectations)
        end

        it 'should traverse the parse graph backwards' do
          walker = subject.build_walker(sample_result)
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
          
          event18 = walker.next
          expectations = [:visit, 'S => A T . | 0', 4]
          event_expectations(event18, expectations)

          event19 = walker.next
          expectations = [:revisit, 'T. | 1', 4]
          event_expectations(event19, expectations)

          # Multiple visit occurred: jump to antecedent of start entry
          event20 = walker.next
          expectations = [:visit, 'S => A . T | 0', 1]
          event_expectations(event20, expectations)

          event21 = walker.next
          expectations = [:visit, 'A. | 0', 1]
          event_expectations(event21, expectations)
          
          # Backtrack created: first alternative selected
          event22 = walker.next
          expectations = [:visit, 'A => a . | 0', 1]
          event_expectations(event22, expectations)                     
          
          event23 = walker.next
          expectations = [:visit, 'A => . a | 0', 0]
          event_expectations(event23, expectations)

          event24 = walker.next
          expectations = [:visit, '.A | 0', 0]
          event_expectations(event24, expectations)

          event25 = walker.next
          expectations = [:visit, 'S => . A T | 0', 0]
          event_expectations(event25, expectations)

          # Backtracking is occurring
          event26 = walker.next
          expectations = [:backtrack, 'A. | 0', 1]
          event_expectations(event26, expectations)          
          
          event27 = walker.next
          expectations = [:visit, 'A => B A . | 0', 1]
          event_expectations(event27, expectations)
          
          event28 = walker.next
          expectations = [:revisit, 'A. | 0', 1]
          event_expectations(event28, expectations)

          event29 = walker.next
          expectations = [:visit, 'A => B . A | 0', 0]
          event_expectations(event29, expectations)           

          event30 = walker.next
          expectations = [:visit, 'B. | 0', 0]
          event_expectations(event30, expectations)

          event31 = walker.next
          expectations = [:visit, 'B => . | 0', 0]
          event_expectations(event31, expectations)

          event32 = walker.next
          expectations = [:visit, '.B | 0', 0]
          event_expectations(event32, expectations)  

          event33 = walker.next
          expectations = [:visit, 'A => . B A | 0', 0]
          event_expectations(event33, expectations)        
        end
        
        it 'should raise an exception at end of visit' do
          walker = subject.build_walker(sample_result)
          32.times { walker.next }
          
          expect{ walker.next }.to raise_error(StopIteration)
        end

      end # context
    end # describe
  end # module
end # module
# End of file