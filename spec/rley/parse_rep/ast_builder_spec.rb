# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/parser/parse_walker_factory'
# require_relative '../../../lib/rley/parser/parse_tree_builder'
require_relative '../../../lib/rley/parse_rep/ast_base_builder'
require_relative '../../../lib/rley/ptree/parse_tree'

require_relative '../support/expectation_helper'
require_relative '../support/grammar_b_expr_helper'
require_relative '../support/grammar_arr_int_helper'

module Rley # This module is used as a namespace
  module ParseRep # This module is used as a namespace
    ArrayNode = Struct.new(:children) do
      def initialize
        super
        self.children = []
      end

      def interpret
        return children.map(&:interpret)
      end
    end

    IntegerNode = Struct.new(:value, :position) do
      def initialize(integerToken, aPosition)
        super
        self.value = integerToken.lexeme.to_i
        self.position = aPosition
      end

      def interpret
        value
      end
    end

    # rubocop: disable Naming/VariableNumber
    class ASTBuilder < ASTBaseBuilder
      Terminal2NodeClass = {
        'integer' => IntegerNode
      }.freeze

      def terminal2node
        Terminal2NodeClass
      end

      def reduce_P_0(_aProd, aRange, theTokens, theChildren)
        return_first_child(aRange, theTokens, theChildren)
      end

      # rule 'arr' => %w([ sequence ])
      def reduce_arr_0(_aProd, _range, _tokens, theChildren)
        return theChildren[1]
      end

      # rule 'sequence' => ['list']
      def reduce_sequence_0(_aProd, aRange, theTokens, theChildren)
        return_first_child(aRange, theTokens, theChildren)
      end

      # rule 'sequence' => []
      def reduce_sequence_1(_aProd, _range, _tokens, _children)
        return ArrayNode.new
      end

      # rule 'list' => %w[list , integer]
      def reduce_list_0(_aProd, _range, _tokens, theChildren)
        node = theChildren[0]
        node.children << theChildren[2]
        return node
      end

      # rule 'list' => 'integer'
      def reduce_list_1(_aProd, _range, _tokens, theChildren)
        node = ArrayNode.new
        node.children << theChildren[0]
        return node
      end
    end # class
    # rubocop: enable Naming/VariableNumber
  end # module
end # module

module Rley # Open this namespace to avoid module qualifier prefixes
  module ParseRep
    describe ASTBuilder do
      include ExpectationHelper # Mix-in with expectation on parse entry sets
      include GrammarArrIntHelper # Mix-in for array of integers language

      let(:sample_grammar) do
          builder = grammar_arr_int_builder
          builder.grammar
      end

      let(:sample_tokens) do
        arr_int_tokenizer('[2 , 3, 5 ]')
      end

      subject { ASTBuilder.new(sample_tokens) }

      def init_walker(theParser, theTokens)
        result = theParser.parse(theTokens)
        factory = Parser::ParseWalkerFactory.new
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
          expect { ASTBuilder.new(sample_tokens) }.not_to raise_error
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
        def next_event(expectation)
          event = @walker.next
          (ev_type, entry, index) = event
          actual = "#{ev_type} #{entry} #{index}"
          expect(actual).to eq(expectation)
          subject.receive_event(*event)
        end


        before(:each) do
          @parser = Parser::GFGEarleyParser.new(sample_grammar)
          init_walker(@parser, sample_tokens)
        end

        # List of visit events
        # Event: visit P. | 0 7
        # Event: visit P => arr . | 0 7
        # Event: visit arr. | 0 7
        # Event: visit arr => [ sequence ] . | 0 7
        # Event: visit arr => [ sequence . ] | 0 6
        # Event: visit sequence. | 1 6
        # Event: visit sequence => list . | 1 6
        # Event: visit list. | 1 6
        # Event: visit list => list , integer . | 1 6
        # Event: visit list => list , . integer | 1 5
        # Event: visit list => list . , integer | 1 4
        # Event: visit list. | 1 4
        # Event: visit list => list , integer . | 1 4
        # Event: visit list => list , . integer | 1 3
        # Event: visit list => list . , integer | 1 2
        # Event: visit list. | 1 2
        # Event: visit list => integer . | 1 2
        # Event: visit list => . integer | 1 1
        # Event: visit .list | 1 1
        # Event: visit list => . list , integer | 1 1
        # Event: revisit .list | 1 1
        # Event: revisit list => . list , integer | 1 1
        # Event: revisit .list | 1 1
        # Event: visit sequence => . list | 1 1
        # Event: visit .sequence | 1 1
        # Event: visit arr => [ . sequence ] | 0 1
        # Event: visit arr => . [ sequence ] | 0 0
        # Event: visit .arr | 0 0
        # Event: visit P => . arr | 0 0
        # Event: visit .P | 0 0

        it 'should accept a first visit event' do
          stack = get_stack(subject)

          next_event('visit P. | 0 7')
          expect(stack.size).to eq(1)
          # stack: [P[0, 7]]
          expect(stack.last.range).to eq(create_range(0, 7))
          expect(stack.last.children).to be_nil
        end

        it 'should build a tree for an empty array' do
          stack = get_stack(subject)

          next_event('visit P. | 0 7')

          next_event('visit P => arr . | 0 7')
          # stack: [P[0, 7]]
          expect(stack.last.children.size).to eq(1)

          next_event('visit arr. | 0 7')
          expect(stack.size).to eq(2)
          # stack: [P[0, 7], arr[0, 7]]
          expect(stack.last.range).to eq(create_range(0, 7))
          expect(stack.last.children).to be_nil

          next_event('visit arr => [ sequence ] . | 0 7')
          # stack: [P[0, 7], arr[0, 7]]
          rbracket = stack.last.children[-1]
          expect(rbracket).to be_kind_of(PTree::TerminalNode)
          expect(rbracket.to_s).to eq("][6, 7]: ']'")

          next_event('visit arr => [ sequence . ] | 0 6')

          next_event('visit sequence. | 1 6')
          expect(stack.size).to eq(3)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6]]
          expect(stack.last.range).to eq(create_range(1, 6))
          expect(stack.last.children).to be_nil

          next_event('visit sequence => list . | 1 6')
          expect(stack.last.children.size).to eq(1)

          next_event('visit list. | 1 6')
          expect(stack.size).to eq(4)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6], list[1, 6]]
          expect(stack.last.range).to eq(create_range(1, 6))
          expect(stack.last.children).to be_nil

          next_event('visit list => list , integer . | 1 6')
          intval = stack.last.children[-1]
          expect(intval).to be_kind_of(IntegerNode)
          expect(intval.value).to eq(5)

          next_event('visit list => list , . integer | 1 5')
          comma = stack.last.children[-2]
          expect(comma).to be_kind_of(PTree::TerminalNode)
          expect(comma.to_s).to eq(",[4, 5]: ','")

          next_event('visit list => list . , integer | 1 4')

          next_event('visit list. | 1 4')
          expect(stack.size).to eq(5)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6], list[1, 6], list[1, 4]
          expect(stack.last.range).to eq(create_range(1, 4))
          expect(stack.last.children).to be_nil

          next_event('visit list => list , integer . | 1 4')
          intval = stack.last.children[-1]
          expect(intval).to be_kind_of(IntegerNode)
          expect(intval.value).to eq(3)

          next_event('visit list => list , . integer | 1 3')
          comma = stack.last.children[-2]
          expect(comma).to be_kind_of(PTree::TerminalNode)
          expect(comma.to_s).to eq(",[2, 3]: ','")

          next_event('visit list => list . , integer | 1 2')

          next_event('visit list. | 1 2')
          expect(stack.size).to eq(6)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6], list[1, 6],
          #        list[1, 4], list[1, 2]
          expect(stack.last.range).to eq(create_range(1, 2))
          expect(stack.last.children).to be_nil

          next_event('visit list => integer . | 1 2')
          intval = stack.last.children[-1]
          expect(intval).to be_kind_of(IntegerNode)
          expect(intval.value).to eq(2)

          next_event('visit list => . integer | 1 1')
          expect(stack.size).to eq(5)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6], list[1, 6], list[1, 4]
          list_node = stack.last.children[0]
          expect(list_node).to be_kind_of(ArrayNode)
          expect(list_node.children.size).to eq(1)
          expect(list_node.children.last.value).to eq(2)

          next_event('visit .list | 1 1')

          next_event('visit list => . list , integer | 1 1')
          expect(stack.size).to eq(4)
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6], list[1, 6]
          list_node = stack.last.children[0]
          expect(list_node).to be_kind_of(ArrayNode)
          expect(list_node.children.size).to eq(2)
          expect(list_node.children.last.value).to eq(3)

          next_event('revisit .list | 1 1')

          next_event('revisit list => . list , integer | 1 1')
          # stack: [P[0, 7], arr[0, 7], sequence[1, 6]
          list_node = stack.last.children.last
          expect(list_node).to be_kind_of(ArrayNode)
          expect(list_node.children.size).to eq(3)
          expect(list_node.children.last.value).to eq(5)

          next_event('revisit .list | 1 1')

          next_event('visit sequence => . list | 1 1')
          expect(stack.size).to eq(2)
          # stack: [P[0, 7], arr[0, 7]
          list_node = stack.last.children[1]
          expect(list_node).to be_kind_of(ArrayNode)
          expect(list_node.children.size).to eq(3)

          next_event('visit .sequence | 1 1')

          next_event('visit arr => [ . sequence ] | 0 1')
          lbracket = stack.last.children[0]
          expect(lbracket).to be_kind_of(PTree::TerminalNode)
          expect(lbracket.to_s).to eq("[[0, 1]: '['")

          next_event('visit arr => . [ sequence ] | 0 0')
          expect(stack.size).to eq(1)
          # stack: [P[0, 7]
          array_node = stack.last.children[0]
          expect(array_node).to be_kind_of(ArrayNode)
          expect(array_node.children.size).to eq(3)


          next_event('visit .arr | 0 0')

          next_event('visit P => . arr | 0 0')
          expect(stack.size).to eq(0)
          expect(subject.result).not_to be_nil
          root = subject.result.root
          expect(root.interpret).to eq([2, 3, 5])

          next_event('visit .P | 0 0')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
