require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'

require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'

require_relative '../../../lib/rley/parser/parse_walker_factory'

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

      let(:walker) do
        factory = ParseWalkerFactory.new
        factory.build_walker(sample_result)
      end

      subject do
        ParseForestBuilder.new(sample_result)
      end

      # Emit a text representation of the current path.
      def path_to_s()
        text_parts = subject.curr_path.map { |path_element|  path_element.to_string(0) }
        return text_parts.join('/')
      end


      context 'Initialization:' do
        it 'should be created with a GFGParsing' do
          expect { ParseForestBuilder.new(sample_result) }.not_to raise_error
        end

        it 'should know the parse result' do
          expect(subject.parsing).to eq(sample_result)
        end

        it 'should have an empty path' do
          expect(subject.curr_path).to be_empty
        end
      end

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

          expect(subject.curr_parent.to_string(0)).to eq('S[?, 4]')
          expected_path2 = 'Phi[0, 4]/S[?, 4]'
          expect(path_to_s).to eq(expected_path2)
        end

        it 'should build alternative node when detecting backtrack point' do
          2.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event3 = walker.next
          subject.receive_event(*event3)

          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => a T .)[0, 4]')
          expected_path3 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path3)
          expect(subject.curr_path[-2].refinement).to eq(:or)
        end

        it 'should build token node when scan edge was detected' do
          3.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event4 = walker.next
          subject.receive_event(*event4)
          expect(event4[1].to_s).to eq('S => a T . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('T[?, 4]')
          expected_path4 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[?, 4]'
          expect(path_to_s).to eq(expected_path4)
          expect(subject.curr_parent.subnodes).to be_empty

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
          expect(subject.curr_parent.subnodes.first.to_string(0)).to eq(token_event6)

          event7 = walker.next
          subject.receive_event(*event7)
          expect(event7[1].to_s).to eq('T => b b . b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path7 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path7)
          expect(subject.curr_parent.subnodes.size).to eq(2)
          token_event7 = 'b[2, 3]'
          expect(subject.curr_parent.subnodes.first.to_string(0)).to eq(token_event7)

          event8 = walker.next
          subject.receive_event(*event8)
          expect(event8[1].to_s).to eq('T => b . b b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path8 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path8)
          expect(subject.curr_parent.subnodes.size).to eq(3)
          token_event8 = 'b[1, 2]'
          expect(subject.curr_parent.subnodes.first.to_string(0)).to eq(token_event8)

          event9 = walker.next
          subject.receive_event(*event9)
          expect(event9[1].to_s).to eq('T => . b b b | 1')
          expect(subject.curr_parent.to_string(0)).to eq('T[1, 4]')
          expected_path9 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]/T[1, 4]'
          expect(path_to_s).to eq(expected_path9)

          event10 = walker.next
          subject.receive_event(*event10)
          expect(event10[1].to_s).to eq('.T | 1')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => a T .)[0, 4]')
          expected_path10 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path10)

          event11 = walker.next
          subject.receive_event(*event11)
          expect(event11[1].to_s).to eq('S => a . T | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => a T .)[0, 4]')
          expected_path11 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path11)
          expect(subject.curr_parent.subnodes.size).to eq(2)
          token_event11 = 'a[0, 1]'
          expect(subject.curr_parent.subnodes.first.to_string(0)).to eq(token_event11)

          event12 = walker.next
          subject.receive_event(*event12)
          expect(event12[1].to_s).to eq('S => . a T | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => a T .)[0, 4]')
          expected_path12 = 'Phi[0, 4]/S[0, 4]/Alt(S => a T .)[0, 4]'
          expect(path_to_s).to eq(expected_path12)
          expect(subject.curr_parent.subnodes.size).to eq(2)  # Is this OK?

          # Pop all Alternative nodes until no Alternative found, pop this last too
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
          expect(event16[0]).to eq(:backtrack)  # Backtrack event!
          expect(event16[1].to_s).to eq('S. | 0')
          # A new alternative node must be created
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => A T .)[0, 4]')
          expected_path16 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path16)


          event17 = walker.next
          subject.receive_event(*event17)
          expect(event17[1].to_s).to eq('S => A T . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('T[?, 4]')
          expected_path17 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/T[?, 4]'
          expect(path_to_s).to eq(expected_path17)
        end

        it 'should detect second time visit of an entry' do
          17.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event18 = walker.next
          subject.receive_event(*event18)
          expect(event18[0]).to eq(:revisit)  # Revisit event!
          expect(event18[1].to_s).to eq('T. | 1')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => A T .)[0, 4]')
          expected_path18 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path18)

          event19 = walker.next
          subject.receive_event(*event19)
          expect(event19[1].to_s).to eq('S => A . T | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[?, 1]')
          expected_path19 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[?, 1]'
          expect(path_to_s).to eq(expected_path19)

          event20 = walker.next
          subject.receive_event(*event20)
          # Next entry is an end entry...
          expect(event20[1].to_s).to eq('A. | 0')
          # ... with multiple antecedents => alternative nodes required
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => a .)[0, 1]')
          expected_path20 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => a .)[0, 1]'
          expect(path_to_s).to eq(expected_path20)
          expect(subject.curr_path[-2].refinement).to eq(:or)

          event21 = walker.next
          subject.receive_event(*event21)
          expect(event21[1].to_s).to eq('A => a . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => a .)[0, 1]')
          expected_path21 = expected_path20
          expect(path_to_s).to eq(expected_path21)

          event22 = walker.next
          subject.receive_event(*event22)
          expect(event22[1].to_s).to eq('A => . a | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => a .)[0, 1]')
          expected_path22 = expected_path20
          expect(path_to_s).to eq(expected_path22)

          event23 = walker.next
          subject.receive_event(*event23)
          # Next entry is an start entry...
          expect(event23[1].to_s).to eq('.A | 0')
          # ... with multiple antecedents => alternative nodes required
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => A T .)[0, 4]')
          expected_path23 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]'
          expect(path_to_s).to eq(expected_path23)

          event24 = walker.next
          subject.receive_event(*event24)
          expect(event24[1].to_s).to eq('S => . A T | 0')
          # ... with multiple antecedents => alternative nodes required
          expect(subject.curr_parent.to_string(0)).to eq('Alt(S => A T .)[0, 4]')
          expected_path24 = expected_path23
          expect(path_to_s).to eq(expected_path24)
        end

        it 'should handle remaining events' do
          24.times do
            event = walker.next
            subject.receive_event(*event)
          end

          event25 = walker.next
          subject.receive_event(*event25)
          expect(event25[0]).to eq(:backtrack)  # Backtrack event!
          expect(event25[1].to_s).to eq('A. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => B A .)[0, 1]')
          expected_path25 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path25)

          event26 = walker.next
          subject.receive_event(*event26)
          expect(event26[1].to_s).to eq('A => B A . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('A[?, 1]')
          expected_path26 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]/A[?, 1]'
          expect(path_to_s).to eq(expected_path26)

          event27 = walker.next
          subject.receive_event(*event27)
          expect(event27[0]).to eq(:revisit)  # Revisit event!
          expect(event27[1].to_s).to eq('A. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => B A .)[0, 1]')
          expected_path27 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path27)

          event28 = walker.next
          subject.receive_event(*event28)
          expect(event28[0]).to eq(:visit)
          expect(event28[1].to_s).to eq('A => B . A | 0')
          expect(subject.curr_parent.to_string(0)).to eq('B[?, 0]')
          expected_path28 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]/B[?, 0]'
          expect(path_to_s).to eq(expected_path28)

          event29 = walker.next
          subject.receive_event(*event29)
          expect(event29[0]).to eq(:visit)
          expect(event29[1].to_s).to eq('B. | 0')
          expect(subject.curr_parent.to_string(0)).to eq('B[0, 0]')
          expected_path29 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]/B[0, 0]'
          expect(path_to_s).to eq(expected_path29)

          event30 = walker.next
          subject.receive_event(*event30)
          expect(event30[0]).to eq(:visit)
          # Empty production!
          expect(event30[1].to_s).to eq('B => . | 0')
          expect(subject.curr_parent.to_string(0)).to eq('B[0, 0]')
          expected_path30 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]/B[0, 0]'
          expect(path_to_s).to eq(expected_path30)
          
          event31 = walker.next
          subject.receive_event(*event31)
          expect(event31[0]).to eq(:visit)
          expect(event31[1].to_s).to eq('.B | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => B A .)[0, 1]')
          expected_path31 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path31)

          event32 = walker.next
          subject.receive_event(*event32)
          expect(event32[0]).to eq(:visit)
          expect(event32[1].to_s).to eq('A => . B A | 0')
          expect(subject.curr_parent.to_string(0)).to eq('Alt(A => B A .)[0, 1]')
          expected_path32 = 'Phi[0, 4]/S[0, 4]/Alt(S => A T .)[0, 4]/A[0, 1]/Alt(A => B A .)[0, 1]'
          expect(path_to_s).to eq(expected_path32)           
        end   
      end # context

    end # describe
  end # module
end # module
# End of file