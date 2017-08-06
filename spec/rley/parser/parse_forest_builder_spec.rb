require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/parser/parse_walker_factory'

require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'
require_relative '../support/grammar_l0_helper'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_forest_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser
    describe ParseForestBuilder do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      let(:sample_grammar) do
          # Grammar based on paper from Elisabeth Scott
          # "SPPF=Style Parsing From Earley Recognizers" in
          # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
          # contains a hidden left recursion and a cycle
          builder = Syntax::GrammarBuilder.new do
            add_terminals('a', 'b')
            rule 'Phi' => 'S'
            rule 'S' => %w[A T]
            rule 'S' => %w[a T]
            rule 'A' => 'a'
            rule 'A' => %w[B A]
            rule 'B' => []
            rule 'T' => %w[b b b]
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

      subject { ParseForestBuilder.new(sample_tokens) }

      # Emit a text representation of the current path.
      def path_to_s()
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        return text_parts.join('/')
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

      context 'Initialization:' do
        it 'should be created with a sequence of tokens' do
          expect { ParseForestBuilder.new(sample_tokens) }.not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(sample_tokens)
        end

        it 'should have an empty path' do
          expect(subject.curr_path).to be_empty
        end
      end # context

      context 'Parse forest construction' do
        before(:each) do
          factory = ParseWalkerFactory.new
          accept_entry = sample_result.accepting_entry
          accept_index = sample_result.chart.last_index
          @walker = factory.build_walker(accept_entry, accept_index)
        end

        it 'should initialize the root node' do
          next_event(:visit, 'Phi. | 0')
          forest = subject.result

          expect(forest.root.to_string(0)).to eq('Phi[0, 4]')
          expected_curr_path('Phi[0, 4]')
        end

        it 'should initialize the first child of the root node' do
          next_event(:visit, 'Phi. | 0') # Event 1
          next_event(:visit, 'Phi => S . | 0') # Event 2
          next_event(:visit, 'S. | 0') # Event 3

          expected_curr_path('Phi[0, 4]/S[0, 4]')
        end

        it 'should build alternative node when detecting backtrack point' do
          3.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:visit, 'S => a T . | 0') # Event 4
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]')
          expect(subject.curr_path[-2].refinement).to eq(:or)
        end

        it 'should build token node when scan edge was detected' do
          4.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:visit, 'T. | 1') # Event5
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]')
          expect(subject.curr_parent.subnodes).to be_empty

          next_event(:visit, 'T => b b b . | 1') # Event 6
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]')
          expect(subject.curr_parent.subnodes.size).to eq(1)
          expected_first_child('b[3, 4]')

          next_event(:visit, 'T => b b . b | 1') # Event 7
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]')
          expect(subject.curr_parent.subnodes.size).to eq(2)
          expected_first_child('b[2, 3]')

          next_event(:visit, 'T => b . b b | 1') # Event 8
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]')
          expect(subject.curr_parent.subnodes.size).to eq(3)
          expected_first_child('b[1, 2]')

          next_event(:visit, 'T => . b b b | 1') # Event 9
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]')

          next_event(:visit, '.T | 1') # Event 10
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]')

          next_event(:visit, 'S => a . T | 0') # Event 11
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]')
          expect(subject.curr_parent.subnodes.size).to eq(2)
          expected_first_child('a[0, 1]')

          next_event(:visit, 'S => . a T | 0') # Event 12
          # Alternate node is popped
          expected_curr_path('Phi[0, 4]/S[0, 4]')

          next_event(:visit, '.S | 0') # Event 13
          expected_curr_path('Phi[0, 4]')

          next_event(:visit, 'Phi => . S | 0') # Event 14
          expected_curr_path('Phi[0, 4]')

          next_event(:visit, '.Phi | 0') # Event 15
          expect(path_to_s).to be_empty
        end

        it 'should handle backtracking' do
          15.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          # Backtracking is occurring
          next_event(:backtrack, 'S. | 0') # Event 16
          expected_curr_path('Phi[0, 4]/S[0, 4]')

          # Alternate node should be created
          next_event(:visit, 'S => A T . | 0') # Event 17
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]')
          expect(subject.curr_path[-2].refinement).to eq(:or)
        end

        it 'should detect second time visit of an entry' do
          17.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:revisit, 'T. | 1') # REVISIT Event 18
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]')

          next_event(:visit, 'S => A . T | 0') # Event 19
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]')

          next_event(:visit, 'A. | 0') # Event 20
          expected_path20 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]'
          expected_curr_path(expected_path20)
          path_prefix = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/'

          next_event(:visit, 'A => a . | 0') # Event 21
          expected_curr_path(path_prefix + 'Alt(A => a .)[0, 1]')
          expect(subject.curr_path[-2].refinement).to eq(:or)

          next_event(:visit, 'A => . a | 0') # Event 22
          expected_curr_path(expected_path20)

          next_event(:visit, '.A | 0') # Event 23
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]')

          next_event(:visit, 'S => . A T | 0') # Event 24
          expected_curr_path('Phi[0, 4]/S[0, 4]')

          next_event(:revisit, '.S | 0') # REVISIT event 25
          expected_curr_path('Phi[0, 4]')

          next_event(:revisit, 'Phi => . S | 0') # REVISIT event 26
          expected_curr_path('Phi[0, 4]')

          next_event(:revisit, '.Phi | 0') # REVISIT event 27
          expected_curr_path('')
        end

        it 'should handle remaining # Events' do
          27.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          # Backtracking is occurring
          next_event(:backtrack, 'A. | 0') # BACKTRACK Event 28
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]')

          path_prefix = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/'

          next_event(:visit, 'A => B A . | 0') # Event 29
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]')

          next_event(:revisit, 'A. | 0') # REVISIT Event 30
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]')

          next_event(:visit, 'A => B . A | 0') # Event 31
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]')

          next_event(:visit, 'B. | 0') # Event 32
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]/B[0, 0]')

          # Entry with empty production!
          next_event(:visit, 'B => . | 0') # Event 33
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]/B[0, 0]')
          expected_first_child('_[0, 0]')

          next_event(:visit, '.B | 0') # Event 34
          expected_curr_path(path_prefix + 'Alt(A => B A .)[0, 1]')

          next_event(:visit, 'A => . B A | 0') # Event 35
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]')

          next_event(:revisit, '.A | 0') # Event 36
          expected_curr_path('Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]')

          next_event(:revisit, 'S => . A T | 0') # Event 37
          expected_curr_path('Phi[0, 4]/S[0, 4]')

          next_event(:revisit, '.S | 0') # Event 38
          expected_curr_path('Phi[0, 4]')
        end
      end # context

      context 'Natural language processing' do
        include GrammarL0Helper

        let(:grammar_l0) do
          builder = grammar_l0_builder
          builder.grammar
        end

        let(:sentence_tokens) do
          sentence = 'I prefer a morning flight'
          tokenizer_l0(sentence, grammar_l0)
        end

        let(:sentence_result) do
          parser = Parser::GFGEarleyParser.new(grammar_l0)
          parser.parse(sentence_tokens)
        end

        before(:each) do
          factory = ParseWalkerFactory.new
          accept_entry = sentence_result.accepting_entry
          accept_index = sentence_result.chart.last_index
          @walker = factory.build_walker(accept_entry, accept_index)
        end

        subject { ParseForestBuilder.new(sentence_tokens) }

        it 'should handle walker events' do
          next_event(:visit, 'S. | 0') # Event 1
          expected_curr_path('S[0, 5]')

          next_event(:visit, 'S => NP VP . | 0') # Event2
          expected_curr_path('S[0, 5]')

          next_event(:visit, 'VP. | 1') # Event 3
          expected_curr_path('S[0, 5]/VP[1, 5]')

          next_event(:visit, 'VP => Verb NP . | 1') # Event 4
          expected_curr_path('S[0, 5]/VP[1, 5]')

          next_event(:visit, 'NP. | 2') # Event 5
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]')


          next_event(:visit, 'NP => Determiner Nominal . | 2') # Event 6
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]')

          next_event(:visit, 'Nominal. | 3') # Event 7
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]')

          next_event(:visit, 'Nominal => Nominal Noun . | 3') # Event 8
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]')
          expect(subject.curr_parent.subnodes.size).to eq(1)
          expected_first_child('Noun[4, 5]')


          next_event(:visit, 'Nominal => Nominal . Noun | 3') # Event 9
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]')


          next_event(:visit, 'Nominal. | 3') # Event 10
          path10 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expected_curr_path(path10)

          next_event(:visit, 'Nominal => Noun . | 3') # Event11
          path11 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expected_curr_path(path11)
          expect(subject.curr_parent.subnodes.size).to eq(1)
          expected_first_child('Noun[3, 4]')

          next_event(:visit, 'Nominal => . Noun | 3') # Event 12
          path12 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expected_curr_path(path12)

          next_event(:visit, '.Nominal | 3') # Event 13
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]')

          next_event(:visit, 'Nominal => . Nominal Noun | 3') # Event 14
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]')

          next_event(:revisit, '.Nominal | 3') # REVISIT Event 15
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]')

          next_event(:visit, 'NP => Determiner . Nominal | 2') # Event 16 
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]')
          expected_first_child('Determiner[2, 3]')

          next_event(:visit, 'NP => . Determiner Nominal | 2') # Event 17 
          expected_curr_path('S[0, 5]/VP[1, 5]/NP[2, 5]')

          next_event(:visit, '.NP | 2') # Event 18 
          expected_curr_path('S[0, 5]/VP[1, 5]')

          next_event(:visit, 'VP => Verb . NP | 1') # Event 19 
          expected_curr_path('S[0, 5]/VP[1, 5]')
          expected_first_child('Verb[1, 2]')

          next_event(:visit, 'VP => . Verb NP | 1') # Event 20 
          expected_curr_path('S[0, 5]/VP[1, 5]')

          next_event(:visit, '.VP | 1') # Event 21 
          expected_curr_path('S[0, 5]')

          next_event(:visit, 'S => NP . VP | 0') # Event22 
          expected_curr_path('S[0, 5]')

          next_event(:visit, 'NP. | 0') # Event 23 
          expected_curr_path('S[0, 5]/NP[0, 1]')

          next_event(:visit, 'NP => Pronoun . | 0') # Event 24 
          expected_curr_path('S[0, 5]/NP[0, 1]')
          expected_first_child('Pronoun[0, 1]')

          next_event(:visit, 'NP => . Pronoun | 0') # Event 25 
          expected_curr_path('S[0, 5]/NP[0, 1]')

          next_event(:visit, '.NP | 0') # Event 26 
          expected_curr_path('S[0, 5]')

          next_event(:visit, 'S => . NP VP | 0') # Event 27 
          expected_curr_path('S[0, 5]')

          next_event(:visit, '.S | 0') # Event28 
          expected_curr_path('')
        end
      end # context
    end # describe
  end # module
end # module
# End of file
