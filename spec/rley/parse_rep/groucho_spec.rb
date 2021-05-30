# frozen_string_literal: true

# Purpose: to test the parse forest generation for an emblematic
# ambiguous sentence
# Based on example found at: http://www.nltk.org/book_1ed/ch08.html
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
    describe 'Coping with a NLP ambiguous toy grammar' do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      let(:sample_grammar) do
        builder = Rley::Syntax::GrammarBuilder.new do
          add_terminals('N', 'V', 'Pro')  # N(oun), V(erb), Pro(noun)
          add_terminals('Det', 'P')       # Det(erminer), P(reposition)
          rule 'S' => 'NP VP'
          rule 'NP' => 'Det N'
          rule 'NP' => 'Det N PP'
          rule 'NP' => 'Pro'
          rule 'VP' => 'V NP'
          rule 'VP' => 'VP PP'
          rule 'PP' => 'P NP'
        end
        builder.grammar
      end

      # The lexicon is just a Hash with pairs of the form:
      # word => terminal symbol name
      let(:groucho_lexicon) do
        {
          'elephant' => 'N',
          'pajamas' => 'N',
          'shot' => 'V',
          'I' => 'Pro',
          'an' => 'Det',
          'my' => 'Det',
          'in' => 'P'
        }
      end

      # Highly simplified tokenizer implementation.
      def tokenizer(aText, aGrammar)
        pos = Rley::Lexical::Position.new(1, 2) # Dummy position
        aText.scan(/\S+/).map do |word|
          term = groucho_lexicon[word]
          raise StandardError, "Word '#{word}' not found in lexicon" if term.nil?

          terminal = aGrammar.name2symbol[term]
          Rley::Lexical::Token.new(word, terminal, pos)
        end
      end

      let(:sentence_tokens) do
        sentence = 'I shot an elephant in my pajamas'
        tokenizer(sentence, sample_grammar)
      end

      let(:sentence_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sentence_tokens)
      end

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

      def root_children
          subject.result.root.subnodes
      end


      before(:each) do
        factory = Parser::ParseWalkerFactory.new
        accept_entry = sentence_result.accepting_entry
        accept_index = sentence_result.chart.last_index
        @walker = factory.build_walker(accept_entry, accept_index, true)
      end

      context 'Parse ambiguous sentence' do
        subject { ParseForestBuilder.new(sentence_tokens) }

        it 'should build a parse forest with a correct root node' do
          next_event(:visit, 'S. | 0') # Event 1
          expected_curr_path('S[0, 7]')
          # Root node should have no child
          expect(root_children.size).to be_zero

          next_event(:visit, 'S => NP VP . | 0') # Event 2
          expected_curr_path('S[0, 7]')

          next_event(:visit, 'VP. | 1') # Event 3
          expected_curr_path('S[0, 7]/VP[1, 7]')
          # Root node should have one child
          expect(root_children.size).to eq(1)
          expect(root_children.first.to_string(0)).to eq('VP[1, 7]')

          25.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:visit, 'NP. | 0') # Event 29
          expected_curr_path('S[0, 7]/NP[0, 1]')
          # Root node should have two children
          expect(root_children.size).to eq(2)
          expect(root_children.first.to_string(0)).to eq('NP[0, 1]')

          18.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:revisit, 'NP. | 0') # Event 48
          expected_curr_path('S[0, 7]')
          # Root node should still have two children
          expect(root_children.size).to eq(2)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
