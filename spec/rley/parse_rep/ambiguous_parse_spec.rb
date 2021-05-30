# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/parser/parse_walker_factory'

require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'
require_relative '../support/grammar_ambig01_helper'

# Load the class under test
require_relative '../../../lib/rley/parse_rep/parse_forest_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module ParseRep
    describe 'Coping with ambiguous grammar' do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      # Emit a text representation of the current path.
      def path_to_s
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        text_parts.join('/')
      end

      def next_event(eventType, anEntryText)
        event = @walker.next
        subject.receive_event(*event)
        expect(event[0]).to eq(eventType)
        expect(event[1].to_s).to eq(anEntryText)
      end

      def expected_curr_parent(anExpectation)
        expect(subject.curr_parent.to_string(0)).to eq(anExpectation)
      end

      def expected_curr_path(anExpectation)
        expect(path_to_s).to eq(anExpectation)
      end

      def expected_first_child(anExpectation)
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(anExpectation)
      end

      before(:each) do
        factory = Parser::ParseWalkerFactory.new
        accept_entry = sentence_result.accepting_entry
        accept_index = sentence_result.chart.last_index
        @walker = factory.build_walker(accept_entry, accept_index, true)
      end

      context 'Ambiguous expression' do
        include GrammarAmbig01Helper

        let(:grammar_ambig01) do
          builder = grammar_ambig01_builder
          builder.grammar
        end

        let(:expr_tokens) do
          sentence = '2 + 3 * 4'
          tokenizer_ambig01(sentence)
        end

        let(:sentence_result) do
          parser = Parser::GFGEarleyParser.new(grammar_ambig01)
          parser.parse(expr_tokens)
        end

        subject { ParseForestBuilder.new(expr_tokens) }

        it 'should handle walker events' do
          next_event(:visit, 'P. | 0') # Event 1
          expected_curr_path('P[0, 5]')

          next_event(:visit, 'P => S . | 0') # Event 2
          expected_curr_path('P[0, 5]')

          next_event(:visit, 'S. | 0') # Event 3
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:visit, 'S => S * S . | 0') # Event 4
          expected_curr_path('P[0, 5]/S[0, 5]/Alt(S => S * S .)[0, 5]')

          next_event(:visit, 'S. | 4') # Event 5
          path_prefix = 'P[0, 5]/S[0, 5]/Alt(S => S * S .)[0, 5]'
          expected_curr_path("#{path_prefix}/S[4, 5]")

          next_event(:visit, 'S => L . | 4') # Event 6
          expected_path5 = "#{path_prefix}/S[4, 5]"
          expect(path_to_s).to eq(expected_path5)

          next_event(:visit, 'L. | 4') # Event 7
          expected_curr_path("#{path_prefix}/S[4, 5]/L[4, 5]")

          next_event(:visit, 'L => integer . | 4') # Event 8
          expected_curr_path("#{path_prefix}/S[4, 5]/L[4, 5]")
          expected_first_child('integer[4, 5]')

          next_event(:visit, 'L => . integer | 4') # Event 9
          expected_curr_path("#{path_prefix}/S[4, 5]/L[4, 5]")

          next_event(:visit, '.L | 4') # Event 10
          expected_curr_path("#{path_prefix}/S[4, 5]")

          next_event(:visit, 'S => . L | 4') # Event 11
          expected_curr_parent('S[4, 5]')
          expected_curr_path("#{path_prefix}/S[4, 5]")

          next_event(:visit, '.S | 4') # Event 12
          expected_curr_parent('Alt(S => S * S .)[0, 5]')
          expected_curr_path(path_prefix)

          next_event(:visit, 'S => S * . S | 0') # Event 13
          expected_curr_path(path_prefix)
          expected_first_child('*[3, 4]')

          next_event(:visit, 'S => S . * S | 0') # Event 14
          expected_curr_path(path_prefix)

          next_event(:visit, 'S. | 0') # Event 15
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:visit, 'S => S + S . | 0') # Event 16
          expected_curr_parent('S[0, 3]')
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:visit, 'S. | 2') # Event 17
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]")

          next_event(:visit, 'S => L . | 2') # Event 18
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]")

          next_event(:visit, 'L. | 2') # Event 19
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]/L[2, 3]")

          next_event(:visit, 'L => integer . | 2') # Event 20
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]/L[2, 3]")
          expected_first_child('integer[2, 3]')

          next_event(:visit, 'L => . integer | 2') # Event 21
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]/L[2, 3]")

          next_event(:visit, '.L | 2') # Event 22
          expected_curr_parent('S[2, 3]')
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]")

          next_event(:visit, 'S => . L | 2') # Event 23
          expected_curr_path("#{path_prefix}/S[0, 3]/S[2, 3]")

          next_event(:visit, '.S | 2') # Event 24
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:visit, 'S => S + . S | 0') # Event 24
          expected_curr_path("#{path_prefix}/S[0, 3]")
          expected_first_child('+[1, 2]')

          next_event(:visit, 'S => S . + S | 0') # Event 25
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:visit, 'S. | 0') # Event 27
          expected_curr_parent('S[0, 1]')
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]")

          next_event(:visit, 'S => L . | 0') # Event 28
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]")

          next_event(:visit, 'L. | 0') # Event 29
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]/L[0, 1]")

          next_event(:visit, 'L => integer . | 0') # Event 30
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]/L[0, 1]")
          expected_first_child('integer[0, 1]')

          next_event(:visit, 'L => . integer | 0') # Event 31
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]/L[0, 1]")

          next_event(:visit, '.L | 0') # Event 32
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]")

          next_event(:visit, 'S => . L | 0') # Event 33
          expected_curr_path("#{path_prefix}/S[0, 3]/S[0, 1]")

          next_event(:visit, '.S | 0') # Event 34
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:visit, 'S => . S + S | 0') # Event 35
          expected_curr_path("#{path_prefix}/S[0, 3]")

          next_event(:revisit, '.S | 0') # REVISIT Event 36
          expected_curr_parent('Alt(S => S * S .)[0, 5]')
          expected_curr_path(path_prefix)

          next_event(:visit, 'S => . S * S | 0') # Event 37
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:revisit, '.S | 0') # REVISIT Event 38
          expected_curr_path('P[0, 5]')

          next_event(:visit, 'P => . S | 0') # Event 39
          expected_curr_path('P[0, 5]')

          next_event(:visit, '.P | 0') # Event 40
          expected_curr_path('')

          next_event(:backtrack, 'S. | 0') # BACKTRACK Event 41

          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:visit, 'S => S + S . | 0') # Event 42
          expected_curr_parent('Alt(S => S + S .)[0, 5]')
          path_prefix = 'P[0, 5]/S[0, 5]/Alt(S => S + S .)[0, 5]'
          expected_curr_path(path_prefix)

          next_event(:visit, 'S. | 2') # Event 43
          expected_curr_path("#{path_prefix}/S[2, 5]")

          next_event(:visit, 'S => S * S . | 2') # Event 44
          expected_curr_path("#{path_prefix}/S[2, 5]")

          # Up to now everything was running OK.
          # Next steps are going wrong...

          next_event(:revisit, 'S. | 4') # Event 45
          expected_curr_path("#{path_prefix}/S[2, 5]")
          expected_first_child('S[4, 5]')

          next_event(:visit, 'S => S * . S | 2') #  Event 46
          expected_curr_path("#{path_prefix}/S[2, 5]")
          expected_first_child('*[3, 4]')

          next_event(:visit, 'S => S . * S | 2') #  Event 47
          expected_curr_path("#{path_prefix}/S[2, 5]")

          next_event(:revisit, 'S. | 2') #  Event 48
          expected_curr_path("#{path_prefix}/S[2, 5]")

          next_event(:visit, 'S => . S * S | 2') #  Event 49
          expected_curr_path("#{path_prefix}/S[2, 5]")

          next_event(:revisit, '.S | 2') #  Event 50
          expected_curr_parent('Alt(S => S + S .)[0, 5]')
          expected_curr_path(path_prefix)

          # TODO: review previous and next steps...

          next_event(:revisit, 'S => S + . S | 0') #  Event 51
          expected_curr_parent('Alt(S => S + S .)[0, 5]')
          expected_curr_path(path_prefix)
          expected_first_child('+[1, 2]')

          next_event(:revisit, 'S => S . + S | 0') #  Event 52
          expected_curr_path(path_prefix)

          next_event(:revisit, 'S. | 0') #  Event 53
          expected_curr_path('P[0, 5]/S[0, 5]/Alt(S => S + S .)[0, 5]')

          next_event(:revisit, 'S => . S + S | 0') #  Event 54
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:revisit, '.S | 0') #  Event 55
          expected_curr_path('P[0, 5]')

          next_event(:revisit, 'P => . S | 0') #  Event 56
          expected_curr_path('P[0, 5]')

          next_event(:revisit, '.P | 0') #  Event 57
          expected_curr_path('')
        end
      end # context
    end # describe
  end # module
end # module
# End of file
