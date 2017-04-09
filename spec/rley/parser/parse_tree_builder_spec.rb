require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/parser/parse_walker_factory'

require_relative '../support/expectation_helper'
require_relative '../support/grammar_b_expr_helper'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_tree_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser
    describe ParseTreeBuilder do
      include ExpectationHelper # Mix-in with expectation on parse entry sets
      include GrammarBExprHelper # Mix-in for basic arithmetic language

      let(:sample_grammar) do
          builder = grammar_expr_builder()
          builder.grammar
      end

      let(:sample_tokens) do
        expr_tokenizer('2 + 3 * 4', sample_grammar)
      end

      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      subject { ParseTreeBuilder.new(sample_tokens) }

      # Emit a text representation of the current path.
      def path_to_s()
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_s
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
          expect { ParseTreeBuilder.new(sample_tokens) }.not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(sample_tokens)
        end

        it 'should have an empty path' do
          expect(subject.curr_path).to be_empty
        end
      end # context

      context 'Parse tree construction:' do
        before(:each) do
          factory = ParseWalkerFactory.new
          accept_entry = sample_result.accepting_entry
          accept_index = sample_result.chart.last_index
          @walker = factory.build_walker(accept_entry, accept_index)
        end

        it 'should initialize the root node' do
          next_event(:visit, 'P. | 0')
          tree = subject.tree

          expect(tree.root.to_string(0)).to eq('P[0, 5]')
          expected_curr_path('P[0, 5]')
        end

        it 'should initialize the first child of the root node' do
          next_event(:visit, 'P. | 0') # Event 1
          next_event(:visit, 'P => S . | 0') # Event 2
          next_event(:visit, 'S. | 0') # Event 3
          next_event(:visit, 'S => S + M . | 0') # Event 4
          expected_curr_path('P[0, 5]/S[0, 5]')          
          next_event(:visit, 'M. | 2') # Event 5
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]')
          next_event(:visit, 'M => M * T . | 2') # Event 6
          next_event(:visit, 'T. | 4') # Event 7
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/T[4, 5]')
          next_event(:visit, 'T => integer . | 4') # Event 8
        end

        it 'should build token node when scan edge was detected' do
          8.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:visit, 'T => . integer | 4') # Event 9
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/T[4, 5]')
          expected_first_child("integer[4, 5]: '4'")
          expect(subject.curr_parent.subnodes.size).to eq(1)          
        end

        it 'should handle the remaining events' do
          9.times do
            event = @walker.next
            subject.receive_event(*event)
          end

          next_event(:visit, '.T | 4') # Event 10
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]')

          next_event(:visit, 'M => M * . T | 2') # Event 11
          
          next_event(:visit, 'M => M . * T | 2') # Event 12          
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]')
          expect(subject.curr_parent.subnodes.size).to eq(2)
          expected_first_child("*[3, 4]: '*'")

          next_event(:visit, 'M. | 2') # Event 13
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]')

          next_event(:visit, 'M => T . | 2') # Event 14
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]')

          next_event(:visit, 'T. | 2') # Event 15
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]/T[2, 3]')

          next_event(:visit, 'T => integer . | 2') # Event 16
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]/T[2, 3]')
          expect(subject.curr_parent.subnodes.size).to eq(1)
          expected_first_child("integer[2, 3]: '3'")

          next_event(:visit, 'T => . integer | 2') # Event 17
          
          next_event(:visit, '.T | 2') # Event 18
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]')          

          next_event(:visit, 'M => . T | 2') # Event 19
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]/M[2, 3]')

          next_event(:visit, '.M | 2') # Event 20
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]')
 
          next_event(:visit, 'M => . M * T | 2') # Event 21
          expected_curr_path('P[0, 5]/S[0, 5]/M[2, 5]') 

          next_event(:revisit, '.M | 2') # Revisit Event 22
          expected_curr_path('P[0, 5]/S[0, 5]')          
 
          next_event(:visit, 'S => S + . M | 0') # Event 23
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:visit, 'S => S . + M | 0') # Event 24
          expected_curr_path('P[0, 5]/S[0, 5]')
          expect(subject.curr_parent.subnodes.size).to eq(2)
          expected_first_child("+[1, 2]: '+'")          
          
          next_event(:visit, 'S. | 0') # Event 25
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]')          

          next_event(:visit, 'S => M . | 0') # Event 26
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]')
          
          next_event(:visit, 'M. | 0') # Event 27
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]')

          next_event(:visit, 'M => T . | 0') # Event 28
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]') 

          next_event(:visit, 'T. | 0') # Event 29
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]/T[0, 1]')           

          next_event(:visit, 'T => integer . | 0') # Event 30
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]/T[0, 1]')

          next_event(:visit, 'T => . integer | 0') # Event 31
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]/T[0, 1]')
          expect(subject.curr_parent.subnodes.size).to eq(1)
          expected_first_child("integer[0, 1]: '2'")

          next_event(:visit, '.T | 0') # Event 32
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]')  

          next_event(:visit, 'M => . T | 0') # Event 33
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]/M[0, 1]')           

          next_event(:visit, '.M | 0') # Event 34
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]') 

          next_event(:visit, 'S => . M | 0') # Event 35
          expected_curr_path('P[0, 5]/S[0, 5]/S[0, 1]')
          
          next_event(:visit, '.S | 0') # Event 36
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:visit, 'S => . S + M | 0') # Event 37
          expected_curr_path('P[0, 5]/S[0, 5]')

          next_event(:revisit, '.S | 0') # Event 38
          expected_curr_path('P[0, 5]')

          next_event(:visit, 'P => . S | 0') # Event 39
          expected_curr_path('P[0, 5]')            

          next_event(:visit, '.P | 0') # Event 39         
          expect(path_to_s).to be_empty
        end
        
        it 'should build parse trees' do
          loop do
            event = @walker.next
            subject.receive_event(*event)
            break if path_to_s.empty?
          end

          # Lightweight sanity check
          expect(subject.tree).not_to be_nil
          expect(subject.tree).to be_kind_of(PTree::ParseTree)
          expect(subject.tree.root.to_s).to eq('P[0, 5]')
          expect(subject.tree.root.subnodes.size).to eq(1)
          child_node = subject.tree.root.subnodes[0]
          expect(child_node.to_s).to eq('S[0, 5]')
          expect(child_node.subnodes.size).to eq(3)
          first_grandchild = child_node.subnodes[0]
          expect(first_grandchild.to_s).to eq('S[0, 1]')
          second_grandchild = child_node.subnodes[1]
          expect(second_grandchild.to_s).to eq("+[1, 2]: '+'")
          third_grandchild = child_node.subnodes[2]
          expect(third_grandchild.to_s).to eq('M[2, 5]')           
        end
      end # context

    end # describe
  end # module
end # module
# End of file
