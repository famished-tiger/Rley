require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/parser/parse_walker_factory'

require_relative '../support/expectation_helper'
require_relative '../support/grammar_b_expr_helper'
require_relative '../support/grammar_arr_int_helper'

# Load the class under test
require_relative '../../../lib/rley/parser/cst_builder'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser
    describe CSTBuilder do
      include ExpectationHelper # Mix-in with expectation on parse entry sets
      include GrammarBExprHelper # Mix-in for basic arithmetic language
      include GrammarArrIntHelper # Mix-in for array of integers language

      let(:sample_grammar) do
          builder = grammar_expr_builder
          builder.grammar
      end

      let(:sample_tokens) do
        expr_tokenizer('2 + 3 * 4', sample_grammar)
      end

      subject { CSTBuilder.new(sample_tokens) }

      def init_walker(theParser, theTokens)
        result = theParser.parse(theTokens)
        factory = ParseWalkerFactory.new
        accept_entry = result.accepting_entry
        accept_index = result.chart.last_index
        @walker = factory.build_walker(accept_entry, accept_index)
      end

      def skip_events(count)
        count.times do
          event = @walker.next
          subject.receive_event(*event)
        end
      end

      def get_stack(aBuilder)
        return aBuilder.send(:stack)
      end

      def create_range(low, high)
        return Lexical::TokenRange.new(low: low, high: high)
      end

      context 'Initialization:' do
        it 'should be created with a sequence of tokens' do
          expect { CSTBuilder.new(sample_tokens) }.not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(sample_tokens)
        end

        it "shouldn't know the result yet" do
          expect(subject.result).to be_nil
        end

        it 'should have an empty stack' do
          expect(subject.send(:stack)).to be_empty
        end
      end # context

      
      
      context 'Parse tree construction (no null symbol):' do
        before(:each) do
          parser = Parser::GFGEarleyParser.new(sample_grammar)
          init_walker(parser, sample_tokens)
        end

        # Event: visit P. | 0 5
        # Event: visit P => S . | 0 5
        # Event: visit S. | 0 5
        # Event: visit S => S + M . | 0 5
        # Event: visit M. | 2 5
        # Event: visit M => M * T . | 2 5
        # Event: visit T. | 4 5
        # Event: visit T => integer . | 4 5
        # Event: visit T => . integer | 4 4
        # Event: visit .T | 4 4
        # Event: visit M => M * . T | 2 4
        # Event: visit M => M . * T | 2 3
        # Event: visit M. | 2 3
        # Event: visit M => T . | 2 3
        # Event: visit T. | 2 3
        # Event: visit T => integer . | 2 3
        # Event: visit T => . integer | 2 2
        # Event: visit .T | 2 2
        # Event: visit M => . T | 2 2
        # Event: visit .M | 2 2
        # Event: visit M => . M * T | 2 2
        # Event: revisit .M | 2 2  <= revisit because of left recursive rule
        # Event: visit S => S + . M | 0 2
        # Event: visit S => S . + M | 0 1
        # Event: visit S. | 0 1
        # Event: visit S => M . | 0 1
        # Event: visit M. | 0 1
        # Event: visit M => T . | 0 1
        # Event: visit T. | 0 1
        # Event: visit T => integer . | 0 1
        # Event: visit T => . integer | 0 0
        # Event: visit .T | 0 0
        # Event: visit M => . T | 0 0
        # Event: visit .M | 0 0
        # Event: visit S => . M | 0 0
        # Event: visit .S | 0 0
        # Event: visit S => . S + M | 0 0
        # Event: revisit .S | 0 0
        # Event: visit P => . S | 0 0
        # Event: visit .P | 0 0
        
        it 'should react to a first end event' do
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(1)
          expect(stack.last.range).to eq(create_range(0, 5))
          expect(stack.last.children).to be_nil
        end

        it 'should react to a first exit event' do
          skip_events(1)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(1)
        end

        it 'should react to a second end event' do
          skip_events(2)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(2)
          expect(stack.last.range).to eq(create_range(0, 5))
          expect(stack.last.children).to be_nil
        end

        it 'should react to a second exit event' do
          skip_events(3)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(2)
          expect(stack.last.children.size).to eq(3)
        end

        it 'should react to an exit event that creates a terminal node' do
          skip_events(7)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(4)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::TerminalNode)
          expect(child.to_s).to eq("integer[4, 5]: '4'")
        end


        it 'should react to a first entry event' do
          skip_events(8)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(3) # Element popped
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('T[4, 5]')
        end

        it 'should react to a first start event' do
          skip_events(9)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(3)
        end

        it 'should react to an middle event that creates a terminal node' do
          skip_events(10)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(3)
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children[1]
          expect(child).to be_kind_of(PTree::TerminalNode)
          expect(child.to_s).to eq("*[3, 4]: '*'")
        end

        it 'should react to an exit event that creates a terminal node' do
          skip_events(15)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(5)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::TerminalNode)
          expect(child.to_s).to eq("integer[2, 3]: '3'")
        end

        it 'should ignore to a revisit event' do
          skip_events(21)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(2)
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('M[2, 5]')
        end

        it 'should react to a 2nd middle event that creates a terminal node' do
          skip_events(22)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(2)
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children[1]
          expect(child).to be_kind_of(PTree::TerminalNode)
          expect(child.to_s).to eq("+[1, 2]: '+'")
        end

        it 'should react to a exit event that creates a terminal node' do
          skip_events(29)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(5)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::TerminalNode)
          expect(child.to_s).to eq("integer[0, 1]: '2'")
        end


        it 'should react to entry event 31' do
          skip_events(30)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(4)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('T[0, 1]')
        end

        it 'should react to entry event 33' do
          skip_events(32)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(3)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[-1]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('M[0, 1]')
        end

        it 'should react to entry event 35' do
          skip_events(34)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(2)
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children[0]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('S[0, 1]')
        end

        it 'should react to entry event 37' do
          skip_events(36)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack.size).to eq(1)
          expect(stack.last.children.size).to eq(1)
          child = stack.last.children[0]
          expect(child).to be_kind_of(PTree::NonTerminalNode)
          expect(child.to_s).to eq('S[0, 5]')
        end

        it 'should react to entry event that creates the tree' do
          skip_events(38)
          event = @walker.next
          expect { subject.receive_event(*event) }.not_to raise_error
          stack = get_stack(subject)
          expect(stack).to be_empty
          expect(subject.result).to be_kind_of(PTree::ParseTree)

          # Lightweight sanity check
          expect(subject.result.root.to_s).to eq('P[0, 5]')
          expect(subject.result.root.subnodes.size).to eq(1)
          child_node = subject.result.root.subnodes[0]
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

      context 'Parse tree construction with null symbol:' do
        def next_event(expectation)
          event = @walker.next
          (ev_type, entry, index) = event
          actual = "#{ev_type} #{entry} #{index}"
          expect(actual).to eq(expectation)
          @instance.receive_event(*event)
        end

        let(:array_grammar) do
            builder = grammar_arr_int_builder
            builder.grammar
        end

        before(:each) do
          @parser = Parser::GFGEarleyParser.new(array_grammar)
        end

        # The visit events were generated with the following snippets:
        # 13.times do
        #   event = @walker.next
        #   subject.receive_event(*event)
        # end
        # The events are:
        # Event: visit P. | 0 2
        # Event: visit P => arr . | 0 2
        # Event: visit arr. | 0 2
        # Event: visit arr => [ sequence ] . | 0 2
        # Event: visit arr => [ sequence . ] | 0 1
        # Event: visit sequence. | 1 1
        # Event: visit sequence => . | 1 1
        # Event: visit .sequence | 1 1
        # Event: visit arr => [ . sequence ] | 0 1
        # Event: visit arr => . [ sequence ] | 0 0
        # Event: visit .arr | 0 0
        # Event: visit P => . arr | 0 0
        #   Event: visit .P | 0 0
        it 'should build a tree for an empty array' do
          empty_arr_tokens = arr_int_tokenizer('[ ]', array_grammar)
          @instance = CSTBuilder.new(empty_arr_tokens)
          init_walker(@parser, empty_arr_tokens)
          stack = get_stack(@instance)

          next_event('visit P. | 0 2')
          expect(stack.size).to eq(1)
          # stack: [P[0, 2]]
          expect(stack.last.range).to eq(create_range(0, 2))
          expect(stack.last.children).to be_nil

          next_event('visit P => arr . | 0 2')
          expect(stack.last.children.size).to eq(1)

          next_event('visit arr. | 0 2')
          expect(stack.size).to eq(2)
          # stack: [arr[0, 2], P[0, 2]]
          expect(stack.last.range).to eq(create_range(0, 2))
          expect(stack.last.children).to be_nil

          next_event('visit arr => [ sequence ] . | 0 2')
          expect(stack.size).to eq(2)
          expect(stack.last.range).to eq(create_range(0, 2))
          expect(stack.last.children.size).to eq(3)
          child = stack.last.children.last
          expect(child.to_s).to eq("][1, 2]: ']'")

          next_event('visit arr => [ sequence . ] | 0 1')
          expect(stack.size).to eq(2)

          next_event('visit sequence. | 1 1')
          expect(stack.size).to eq(3)
          # stack: [sequence[1, 1], arr[0, 2], P[0, 2]]
          expect(stack.last.range).to eq(create_range(1, 1))
          expect(stack.last.children).to be_nil

          next_event('visit sequence => . | 1 1')
          expect(stack.size).to eq(2)
          # stack: [arr[0, 2], P[0, 2]]
          expect(stack.last.range).to eq(create_range(0, 2))
          sequence = stack.last.children[1]
          expect(sequence).to be_kind_of(PTree::NonTerminalNode)
          expect(sequence.subnodes).to be_empty
          expect(sequence.to_s).to eq('sequence[1, 1]')

          next_event('visit .sequence | 1 1')
          expect(stack.size).to eq(2)

          next_event('visit arr => [ . sequence ] | 0 1')
          expect(stack.size).to eq(2)
          expect(stack.last.range).to eq(create_range(0, 2))
          sequence = stack.last.children[0]
          expect(sequence).to be_kind_of(PTree::TerminalNode)
          expect(sequence.to_s).to eq("[[0, 1]: '['")

          next_event('visit arr => . [ sequence ] | 0 0')
          expect(stack.size).to eq(1)
          # stack: [P[0, 2]]
          expect(stack.last.range).to eq(create_range(0, 2))
          expect(stack.last.children.size).to eq(1)
          expect(stack.last.children[0]).to be_kind_of(PTree::NonTerminalNode)
          expect(stack.last.children[0].to_s).to eq('arr[0, 2]')

          next_event('visit .arr | 0 0')
          expect(stack.size).to eq(1)

          next_event('visit P => . arr | 0 0')
          expect(stack).to be_empty
          expect(@instance.result).not_to be_nil
          
          next_event('visit .P | 0 0')
          expect(stack).to be_empty
          expect(@instance.result).not_to be_nil          
        end
      end # context
    end # describe
  end # module
end # module
# End of file
