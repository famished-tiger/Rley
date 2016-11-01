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
          builder = Syntax::GrammarBuilder.new
          builder.add_terminals('a', 'b')
          builder.add_production('Phi' => 'S')
          builder.add_production('S' => %w(A T))
          builder.add_production('S' => %w(a T))
          builder.add_production('A' => 'a')
          builder.add_production('A' => %w(B A))
          builder.add_production('B' => [])
          builder.add_production('T' => %w(b b b))
          builder.grammar
      end

      let(:sample_tokens) do
        build_token_sequence(%w(a b b b), sample_grammar)
      end

      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      let(:walker) do
        factory = ParseWalkerFactory.new
        accept_entry = sample_result.accepting_entry
        accept_index = sample_result.chart.last_index
        factory.build_walker(accept_entry, accept_index)
      end

      subject { ParseForestBuilder.new(sample_tokens) }

      # Emit a text representation of the current path.
      def path_to_s()
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        return text_parts.join('/')
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
        it 'should initialize the root node' do
          first_event = walker.next
          subject.receive_event(*first_event)
          forest = subject.forest

          expect(forest.root.to_string(0)).to eq('Phi[0, 4]')
          expect(subject.curr_path).to eq([forest.root])
          expect(subject.entry2node[first_event[1]]).to eq(forest.root)
        end

        it 'should initialize the first child of the root node' do
          event1 = walker.next
          subject.receive_event(*event1)

          event2 = walker.next
          subject.receive_event(*event2)

          event3 = walker.next
          subject.receive_event(*event3)

          expect(subject.curr_parent.to_string(0)).to eq('S[0, 4]')
          expected_path3 = 'Phi[0, 4]/S[0, 4]'
          expect(path_to_s).to eq(expected_path3)
        end

        it 'should build alternative node when detecting backtrack point' do
          3.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event4 = walker.next
          subject.receive_event(*event4)

          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => a T .)[0, 4]')
          expected_path4 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path4)
          expect(subject.curr_path[-2].refinement).to eq(:or)
        end

        it 'should build token node when scan edge was detected' do
          4.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event5 = walker.next
          subject.receive_event(*event5)
          expect(event5[1].to_s).to eq('T. | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path5 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path5)
          expect(subject.curr_parent.subnodes).to be_empty

          event6 = walker.next
          subject.receive_event(*event6)
          expect(event6[1].to_s).to eq('T => b b b . | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path6 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path6)
          expect(subject.curr_parent.subnodes.size).to eq(1)
          token_event6 = 'b[3, 4]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event6)

          event7 = walker.next
          subject.receive_event(*event7)
          expect(event7[1].to_s).to eq('T => b b . b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path7 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path7)
          expect(subject.curr_parent.subnodes.size).to eq(2)
          token_event7 = 'b[2, 3]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event7)

          event8 = walker.next
          subject.receive_event(*event8)
          expect(event8[1].to_s).to eq('T => b . b b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path8 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path8)
          expect(subject.curr_parent.subnodes.size).to eq(3)
          token_event8 = 'b[1, 2]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event8)

          event9 = walker.next
          subject.receive_event(*event9)
          expect(event9[1].to_s).to eq('T => . b b b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path9 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path9)

          event10 = walker.next
          subject.receive_event(*event10)
          expect(event10[1].to_s).to eq('.T | 1')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => a T .)[0, 4]')
          expected_path10 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path10)

          event11 = walker.next
          subject.receive_event(*event11)
          expect(event11[1].to_s).to eq('S => a . T | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => a T .)[0, 4]')
          expected_path11 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path11)
          expect(subject.curr_parent.subnodes.size).to eq(2)
          token_event11 = 'a[0, 1]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event11)

          event12 = walker.next
          subject.receive_event(*event12)
          expect(event12[1].to_s).to eq('S => . a T | 0')

          # Alternate node is popped
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 4]')
          expected_path12 = 'Phi[0, 4]/S[0, 4]'
          expect(path_to_s).to eq(expected_path12)

          event13 = walker.next
          subject.receive_event(*event13)
          expect(event13[1].to_s).to eq('.S | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Phi[0, 4]')
          expected_path13 = 'Phi[0, 4]'
          expect(path_to_s).to eq(expected_path13)

          event14 = walker.next
          subject.receive_event(*event14)
          expect(event14[1].to_s).to eq('Phi => . S | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Phi[0, 4]')
          expected_path14 = 'Phi[0, 4]'
          expect(path_to_s).to eq(expected_path14)

          event15 = walker.next
          subject.receive_event(*event15)
          expect(event15[1].to_s).to eq('.Phi | 0')
          expect(path_to_s).to be_empty
        end

        it 'should handle backtracking' do
          15.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event16 = walker.next
          subject.receive_event(*event16)
          expect(event16[0]).to eq(:backtrack) # Backtrack event!
          expect(event16[1].to_s).to eq('S. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 4]')
          expected_path16 = 'Phi[0, 4]/S[0, 4]'
          expect(path_to_s).to eq(expected_path16)

          # Alternate node should be created
          event17 = walker.next
          subject.receive_event(*event17)
          expect(event17[1].to_s).to eq('S => A T . | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => A T .)[0, 4]')
          expected_path17 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path17)
          expect(subject.curr_path[-2].refinement).to eq(:or)
        end

        it 'should detect second time visit of an entry' do
          17.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event18 = walker.next
          subject.receive_event(*event18)
          expect(event18[0]).to eq(:revisit) # Revisit event!
          expect(event18[1].to_s).to eq('T. | 1')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => A T .)[0, 4]')
          expected_path18 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path18)

          event19 = walker.next
          subject.receive_event(*event19)
          expect(event19[1].to_s).to eq('S => A . T | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => A T .)[0, 4]')
          expected_path19 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path19)

          event20 = walker.next
          subject.receive_event(*event20)
          # Next entry is an end entry...
          expect(event20[1].to_s).to eq('A. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[0, 1]')
          expected_path20 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]'
          expect(path_to_s).to eq(expected_path20)


          event21 = walker.next
          subject.receive_event(*event21)
          expect(event21[1].to_s).to eq('A => a . | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(A => a .)[0, 1]')
          path_prefix = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/'
          expected_path21 = path_prefix + 'Alt(A => a .)[0, 1]'
          expect(path_to_s).to eq(expected_path21)
          expect(subject.curr_path[-2].refinement).to eq(:or)

          event22 = walker.next
          subject.receive_event(*event22)
          expect(event22[1].to_s).to eq('A => . a | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[0, 1]')
          expected_path22 = expected_path20
          expect(path_to_s).to eq(expected_path22)

          event23 = walker.next
          subject.receive_event(*event23)
          expect(event23[1].to_s).to eq('.A | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => A T .)[0, 4]')
          expected_path23 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path23)

          event24 = walker.next
          subject.receive_event(*event24)
          expect(event24[1].to_s).to eq('S => . A T | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 4]')
          expected_path24 = 'Phi[0, 4]/S[0, 4]'
          expect(path_to_s).to eq(expected_path24)

          event25 = walker.next
          subject.receive_event(*event25)
          expect(event25[0]).to eq(:revisit)  # Revisit event!
          expect(event25[1].to_s).to eq('.S | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Phi[0, 4]')
          expected_path25 = 'Phi[0, 4]'
          expect(path_to_s).to eq(expected_path25)

          event26 = walker.next
          subject.receive_event(*event26)
          expect(event26[0]).to eq(:revisit)  # Revisit event!
          expect(event26[1].to_s).to eq('.Phi | 0')
          expected_path26 = ''
          expect(path_to_s).to eq(expected_path26)
        end

        it 'should handle remaining events' do
          26.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event27 = walker.next
          subject.receive_event(*event27)
          expect(event27[0]).to eq(:backtrack) # Backtrack event!
          expect(event27[1].to_s).to eq('A. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[0, 1]')
          expected_path27 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]'
          expect(path_to_s).to eq(expected_path27)

          event28 = walker.next
          subject.receive_event(*event28)
          expect(event28[0]).to eq(:visit)
          expect(event28[1].to_s).to eq('A => B A . | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(A => B A .)[0, 1]')
          path_prefix = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/'
          expected_path28 = path_prefix + 'Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path28)

          event29 = walker.next
          subject.receive_event(*event29)
          expect(event29[0]).to eq(:revisit) # Revisit event!
          expect(event29[1].to_s).to eq('A. | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(A => B A .)[0, 1]')
          expected_path29 = path_prefix + 'Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path29)

          event30 = walker.next
          subject.receive_event(*event30)
          expect(event30[0]).to eq(:visit)
          expect(event30[1].to_s).to eq('A => B . A | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(A => B A .)[0, 1]')
          expected_path30 = path_prefix + 'Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path30)

          event31 = walker.next
          subject.receive_event(*event31)
          expect(event31[0]).to eq(:visit)
          expect(event31[1].to_s).to eq('B. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('B[0, 0]')
          expected_path31 = path_prefix + 'Alt(A => B A .)[0, 1]/B[0, 0]'
          expect(path_to_s).to eq(expected_path31)

          event32 = walker.next
          subject.receive_event(*event32)
          expect(event32[0]).to eq(:visit)
          # Empty production!
          expect(event32[1].to_s).to eq('B => . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('B[0, 0]')
          expected_path30 = path_prefix + 'Alt(A => B A .)[0, 1]/B[0, 0]'
          expect(path_to_s).to eq(expected_path30)

          event33 = walker.next
          subject.receive_event(*event33)
          expect(event33[0]).to eq(:visit)
          expect(event33[1].to_s).to eq('.B | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(A => B A .)[0, 1]')
          expected_path33 = path_prefix + 'Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path33)

          event34 = walker.next
          subject.receive_event(*event34)
          expect(event34[0]).to eq(:visit)
          expect(event34[1].to_s).to eq('A => . B A | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[0, 1]')
          path34 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]'
          expect(path_to_s).to eq(path34)

          event35 = walker.next
          subject.receive_event(*event35)
          expect(event35[0]).to eq(:revisit)
          expect(event35[1].to_s).to eq('.A | 0')
          parent_as_text = subject.curr_parent.to_string(0)
          expect(parent_as_text).to eq('Alt(S => A T .)[0, 4]')
          expected_path35 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path35)

          event36 = walker.next
          subject.receive_event(*event36)
          expect(event36[0]).to eq(:revisit)
          expect(event36[1].to_s).to eq('.S | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 4]')
          expected_path36 = 'Phi[0, 4]/S[0, 4]'
          expect(path_to_s).to eq(expected_path36)

          event37 = walker.next
          subject.receive_event(*event37)
          expect(event37[0]).to eq(:revisit)
          expect(event37[1].to_s).to eq('.Phi | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Phi[0, 4]')
          expected_path37 = 'Phi[0, 4]'
          expect(path_to_s).to eq(expected_path37)
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

        let(:walker) do
          factory = ParseWalkerFactory.new
          accept_entry = sentence_result.accepting_entry
          accept_index = sentence_result.chart.last_index
          factory.build_walker(accept_entry, accept_index)
        end

        subject { ParseForestBuilder.new(sentence_tokens) }

        it 'should handle walker events' do
          event1 = walker.next
          subject.receive_event(*event1)
          expect(event1[0]).to eq(:visit)
          expect(event1[1].to_s).to eq('S. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path1 = 'S[0, 5]'
          expect(path_to_s).to eq(expected_path1)

          event2 = walker.next
          subject.receive_event(*event2)
          expect(event2[0]).to eq(:visit)
          expect(event2[1].to_s).to eq('S => NP VP . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path2 = expected_path1
          expect(path_to_s).to eq(expected_path2)

          event3 = walker.next
          subject.receive_event(*event3)
          expect(event3[0]).to eq(:visit)
          expect(event3[1].to_s).to eq('VP. | 1')
          expect(subject.curr_parent.to_string(0)).to eq('VP[1, 5]')
          expected_path3 = 'S[0, 5]/VP[1, 5]'
          expect(path_to_s).to eq(expected_path3)

          event4 = walker.next
          subject.receive_event(*event4)
          expect(event4[0]).to eq(:visit)
          expect(event4[1].to_s).to eq('VP => Verb NP . | 1')
          expect(subject.curr_parent.to_string(0)).to eq('VP[1, 5]')
          expected_path4 = 'S[0, 5]/VP[1, 5]'
          expect(path_to_s).to eq(expected_path4)

          event5 = walker.next
          subject.receive_event(*event5)
          expect(event5[0]).to eq(:visit)
          expect(event5[1].to_s).to eq('NP. | 2')
          expect(subject.curr_parent.to_string(0)).to eq('NP[2, 5]')
          expected_path5 = 'S[0, 5]/VP[1, 5]/NP[2, 5]'
          expect(path_to_s).to eq(expected_path5)

          event6 = walker.next
          subject.receive_event(*event6)
          expect(event6[0]).to eq(:visit)
          expect(event6[1].to_s).to eq('NP => Determiner Nominal . | 2')
          expect(subject.curr_parent.to_string(0)).to eq('NP[2, 5]')
          expected_path6 = 'S[0, 5]/VP[1, 5]/NP[2, 5]'
          expect(path_to_s).to eq(expected_path6)

          event7 = walker.next
          subject.receive_event(*event7)
          expect(event7[0]).to eq(:visit)
          expect(event7[1].to_s).to eq('Nominal. | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 5]')
          expected_path7 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]'
          expect(path_to_s).to eq(expected_path7)

          event8 = walker.next
          subject.receive_event(*event8)
          expect(event8[0]).to eq(:visit)
          expect(event8[1].to_s).to eq('Nominal => Nominal Noun . | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 5]')
          expected_path8 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]'
          expect(path_to_s).to eq(expected_path8)
          expect(subject.curr_parent.subnodes.size).to eq(1)
          token_event8 = 'Noun[4, 5]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event8)

          event9 = walker.next
          subject.receive_event(*event9)
          expect(event9[0]).to eq(:visit)
          expect(event9[1].to_s).to eq('Nominal => Nominal . Noun | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 5]')
          expected_path9 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]'
          expect(path_to_s).to eq(expected_path9)

          event10 = walker.next
          subject.receive_event(*event10)
          expect(event10[0]).to eq(:visit)
          expect(event10[1].to_s).to eq('Nominal. | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 4]')
          path10 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expect(path_to_s).to eq(path10)

          event11 = walker.next
          subject.receive_event(*event11)
          expect(event11[0]).to eq(:visit)
          expect(event11[1].to_s).to eq('Nominal => Noun . | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 4]')
          path11 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expect(path_to_s).to eq(path11)
          expect(subject.curr_parent.subnodes.size).to eq(1)
          token_event11 = 'Noun[3, 4]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event11)

          event12 = walker.next
          subject.receive_event(*event12)
          expect(event12[0]).to eq(:visit)
          expect(event12[1].to_s).to eq('Nominal => . Noun | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 4]')
          path12 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]/Nominal[3, 4]'
          expect(path_to_s).to eq(path12)

          event13 = walker.next
          subject.receive_event(*event13)
          expect(event13[0]).to eq(:visit)
          expect(event13[1].to_s).to eq('.Nominal | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 5]')
          expected_path13 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]'
          expect(path_to_s).to eq(expected_path13)

          event14 = walker.next
          subject.receive_event(*event14)
          expect(event14[0]).to eq(:visit)
          expect(event14[1].to_s).to eq('Nominal => . Nominal Noun | 3')
          expect(subject.curr_parent.to_string(0)).to eq('Nominal[3, 5]')
          expected_path14 = 'S[0, 5]/VP[1, 5]/NP[2, 5]/Nominal[3, 5]'
          expect(path_to_s).to eq(expected_path14)

          event15 = walker.next
          subject.receive_event(*event15)
          expect(event15[0]).to eq(:revisit)
          expect(event15[1].to_s).to eq('.Nominal | 3')
          expect(subject.curr_parent.to_string(0)).to eq('NP[2, 5]')
          expected_path15 = 'S[0, 5]/VP[1, 5]/NP[2, 5]'
          expect(path_to_s).to eq(expected_path15)

          event16 = walker.next
          subject.receive_event(*event16)
          expect(event16[0]).to eq(:visit)
          expect(event16[1].to_s).to eq('NP => Determiner . Nominal | 2')
          expect(subject.curr_parent.to_string(0)).to eq('NP[2, 5]')
          expected_path16 = 'S[0, 5]/VP[1, 5]/NP[2, 5]'
          expect(path_to_s).to eq(expected_path16)
          token_event16 = 'Determiner[2, 3]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event16)

          event17 = walker.next
          subject.receive_event(*event17)
          expect(event17[0]).to eq(:visit)
          expect(event17[1].to_s).to eq('NP => . Determiner Nominal | 2')
          expect(subject.curr_parent.to_string(0)).to eq('NP[2, 5]')
          expected_path17 = 'S[0, 5]/VP[1, 5]/NP[2, 5]'
          expect(path_to_s).to eq(expected_path17)

          event18 = walker.next
          subject.receive_event(*event18)
          expect(event18[0]).to eq(:visit)
          expect(event18[1].to_s).to eq('.NP | 2')
          expect(subject.curr_parent.to_string(0)).to eq('VP[1, 5]')
          expected_path18 = 'S[0, 5]/VP[1, 5]'
          expect(path_to_s).to eq(expected_path18)

          event19 = walker.next
          subject.receive_event(*event19)
          expect(event19[0]).to eq(:visit)
          expect(event19[1].to_s).to eq('VP => Verb . NP | 1')
          expect(subject.curr_parent.to_string(0)).to eq('VP[1, 5]')
          expected_path19 = 'S[0, 5]/VP[1, 5]'
          expect(path_to_s).to eq(expected_path19)
          token_event19 = 'Verb[1, 2]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event19)

          event20 = walker.next
          subject.receive_event(*event20)
          expect(event20[0]).to eq(:visit)
          expect(event20[1].to_s).to eq('VP => . Verb NP | 1')
          expect(subject.curr_parent.to_string(0)).to eq('VP[1, 5]')
          expected_path20 = 'S[0, 5]/VP[1, 5]'
          expect(path_to_s).to eq(expected_path20)

          event21 = walker.next
          subject.receive_event(*event21)
          expect(event21[0]).to eq(:visit)
          expect(event21[1].to_s).to eq('.VP | 1')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path21 = 'S[0, 5]'
          expect(path_to_s).to eq(expected_path21)

          event22 = walker.next
          subject.receive_event(*event22)
          expect(event22[0]).to eq(:visit)
          expect(event22[1].to_s).to eq('S => NP . VP | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path22 = 'S[0, 5]'
          expect(path_to_s).to eq(expected_path22)

          event23 = walker.next
          subject.receive_event(*event23)
          expect(event23[0]).to eq(:visit)
          expect(event23[1].to_s).to eq('NP. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('NP[0, 1]')
          expected_path23 = 'S[0, 5]/NP[0, 1]'
          expect(path_to_s).to eq(expected_path23)

          event24 = walker.next
          subject.receive_event(*event24)
          expect(event24[0]).to eq(:visit)
          expect(event24[1].to_s).to eq('NP => Pronoun . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('NP[0, 1]')
          expected_path24 = 'S[0, 5]/NP[0, 1]'
          expect(path_to_s).to eq(expected_path24)
          token_event24 = 'Pronoun[0, 1]'
          child = subject.curr_parent.subnodes.first
          expect(child.to_string(0)).to eq(token_event24)

          event25 = walker.next
          subject.receive_event(*event25)
          expect(event25[0]).to eq(:visit)
          expect(event25[1].to_s).to eq('NP => . Pronoun | 0')
          expect(subject.curr_parent.to_string(0)).to eq('NP[0, 1]')
          expected_path25 = 'S[0, 5]/NP[0, 1]'
          expect(path_to_s).to eq(expected_path25)

          event26 = walker.next
          subject.receive_event(*event26)
          expect(event26[0]).to eq(:visit)
          expect(event26[1].to_s).to eq('.NP | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path26 = 'S[0, 5]'
          expect(path_to_s).to eq(expected_path26)

          event27 = walker.next
          subject.receive_event(*event27)
          expect(event27[0]).to eq(:visit)
          expect(event27[1].to_s).to eq('S => . NP VP | 0')
          expect(subject.curr_parent.to_string(0)).to eq('S[0, 5]')
          expected_path27 = 'S[0, 5]'
          expect(path_to_s).to eq(expected_path27)

          event28 = walker.next
          subject.receive_event(*event28)
          expect(event28[0]).to eq(:visit)
          expect(event28[1].to_s).to eq('.S | 0')
          expected_path28 = ''
          expect(path_to_s).to eq(expected_path28)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
