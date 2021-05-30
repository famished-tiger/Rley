# frozen_string_literal: true

require_relative '../spec_helper'

require_relative './support/grammar_helper'
require_relative './support/grammar_sppf_helper'
require_relative '../../lib/rley/lexical/token'
require_relative '../../lib/rley/parser/gfg_earley_parser'
require_relative '../../lib/rley/parse_rep/parse_forest_factory'
require_relative '../../lib/rley/sppf/non_terminal_node'
require_relative '../../lib/rley/sppf/parse_forest'
require_relative '../../lib/rley/formatter/debug'

# Load the class under test
require_relative '../../lib/rley/parse_forest_visitor'

module Rley # Open this namespace to avoid module qualifier prefixes
  describe ParseForestVisitor do
    include GrammarSPPFHelper # Mix-in module with builder for grammar sppf
    include GrammarHelper     # Mix-in with token factory method

    # Assumption the aParseEntry corresponds to an end GFG node
    def create_non_terminal_node(aParseEntry, aRange)
      a_vertex = aParseEntry.vertex
      return Rley::SPPF::NonTerminalNode.new(a_vertex.non_terminal, aRange)
    end

    let(:grammar_sppf) do
      builder = grammar_sppf_builder
      builder.grammar
    end

    let(:sample_tokens) do
      build_token_sequence(%w[a b b b], grammar_sppf)
    end

    # A forest with just a root node
    let(:forest_root) do
      parser = Parser::GFGEarleyParser.new(grammar_sppf)
      parse_result = parser.parse(sample_tokens)
      accepting_entry = parse_result.accepting_entry
      full_range = { low: 0, high: parse_result.chart.last_index }
      root_node = create_non_terminal_node(accepting_entry, full_range)
      Rley::SPPF::ParseForest.new(root_node)
    end

    # Factory method that builds a sample parse forest.
    # Generated forest has the following structure:
    let(:grm_sppf_pforest1) do
      parser = Parser::GFGEarleyParser.new(grammar_sppf)
      parse_result = parser.parse(sample_tokens)
      factory = ParseRep::ParseForestFactory.new(parse_result)
      factory.create
    end


    # Default instantiation rule
    subject { ParseForestVisitor.new(forest_root) }


    context 'Standard creation & initialization:' do
      it 'should be initialized with a parse forest argument' do
        expect { ParseForestVisitor.new(forest_root) }.not_to raise_error
      end

      it 'should know the parse forest to visit' do
        expect(subject.pforest).to eq(forest_root)
      end

      it "shouldn't have subscribers at start" do
        expect(subject.subscribers).to be_empty
      end
    end # context


    context 'Subscribing:' do
      let(:listener1) { double('fake-subscriber1') }
      let(:listener2) { double('fake-subscriber2') }

      it 'should allow subscriptions' do
        subject.subscribe(listener1)
        expect(subject.subscribers.size).to eq(1)
        expect(subject.subscribers).to eq([listener1])

        subject.subscribe(listener2)
        expect(subject.subscribers.size).to eq(2)
        expect(subject.subscribers).to eq([listener1, listener2])
      end

      it 'should allow un-subcriptions' do
        subject.subscribe(listener1)
        subject.subscribe(listener2)
        subject.unsubscribe(listener2)
        expect(subject.subscribers.size).to eq(1)
        expect(subject.subscribers).to eq([listener1])
        subject.unsubscribe(listener1)
        expect(subject.subscribers).to be_empty
      end
    end # context

    # rubocop: disable Lint/ConstantDefinitionInBlock
    class EventDispatcher
      # return [Array<Proc>]
      attr_accessor(:expectations)
      attr_reader(:event_count)

      def initialize
        @event_count = 0
      end

      def accept_all
        true
      end

      def method_missing(mth, *args)
        if expectations.at(event_count)
          if mth =~ /_subnodes$/
            parent = args[0]
            children = args[1]
            expectations[event_count].call(mth, parent, children)
          else
            actual_item = args[0]
            expectations[event_count].call(mth, actual_item)
          end
        end
        @event_count += 1
      end
    end # class
    # rubocop: enable Lint/ConstantDefinitionInBlock

    context 'Notifying visit events:' do
      # expectations [Array<Array<Symbol, String>>]
      def check_event(actual_event, actual_item, expectations)
        (event, item) = expectations
        expect(actual_event).to eq(event)
        case item
          when String
          expect(actual_item.to_string(0)).to eq(item)
        end
      end

      def check_legs(expectations)
        (parent, path_signature) = subject.legs[-1]
        expect(parent.to_string(0)).to eq(expectations[0])
        expect(path_signature).to eq(expectations[1])
      end

      def check_node_accesses(node, paths)
        actual_paths = subject.node_accesses.fetch(node)
        expect(actual_paths).to eq(paths)
      end

      let(:checker) { EventDispatcher.new }

      # Default instantiation rule
      subject do
        instance = ParseForestVisitor.new(grm_sppf_pforest1)
        instance.subscribe(checker)
        instance
      end

      it 'should react to the start_visit_pforest message' do
        # Notify subscribers when start the visit of the pforest
        # expect(listener1).to receive(:before_pforest).with(forest_root)
        checker.expectations = [
          lambda do |event, item|
            check_event(event, item, [:before_pforest, grm_sppf_pforest1])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'Phi[0, 4]'])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'Phi[0, 4]'])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'S[0, 4]'])
            check_legs(['S[0, 4]', 2]) # 2
            check_node_accesses(item, [2])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'S[0, 4]'])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            prediction = 'Alt(S => a T .)[0, 4]'
            check_event(event, item, [:before_alternative, prediction])
            check_legs(['Alt(S => a T .)[0, 4]', 6]) # 2 * 3
            check_node_accesses(item, [6])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(S => a T .)[0, 4]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'a[0, 1]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'a[0, 1]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'T[1, 4]'])
            check_legs(['T[1, 4]', 66]) # 2 * 3 * 11
            check_node_accesses(item, [66])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'T[1, 4]'])
            expect(children.size).to eq(3)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[1, 2]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[1, 2]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[2, 3]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[2, 3]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[3, 4]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[3, 4]'])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'T[1, 4]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'T[1, 4]'])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(S => a T .)[0, 4]'
            check_event(event, parent, [:after_subnodes, prediction])
            expect(children.size).to eq(2)
            check_legs(['Alt(S => a T .)[0, 4]', 6]) # 2 * 3
          end,
          lambda do |event, item|
            prediction = 'Alt(S => a T .)[0, 4]'
            check_event(event, item, [:after_alternative, prediction])
          end,
          lambda do |event, item|
            prediction = 'Alt(S => A T .)[0, 4]'
            check_event(event, item, [:before_alternative, prediction])
            check_legs(['Alt(S => A T .)[0, 4]', 10]) # 2 * 5
            check_node_accesses(item, [10])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(S => A T .)[0, 4]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'A[0, 1]'])
            check_legs(['A[0, 1]', 230]) # 2 * 5 * 23
            check_node_accesses(item, [230])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'A[0, 1]'])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, item, [:before_alternative, prediction])
            check_legs(['Alt(A => a .)[0, 1]', 7130]) # 2 * 5 * 23 * 31
            check_node_accesses(item, [7130])
            # p(subject.legs)
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'a[0, 1]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'a[0, 1]'])
          end,
          lambda do |event, parent, _children|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, parent, [:after_subnodes, prediction])
            check_legs(['Alt(A => a .)[0, 1]', 7130]) # 2 * 5 * 23 * 31
          end,
          lambda do |event, item|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, item, [:after_alternative, prediction])
          end,
          lambda do |event, item|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, item, [:before_alternative, prediction])
            check_legs(['Alt(A => B A .)[0, 1]', 8510]) # 2 * 5 * 23 * 37
            check_node_accesses(item, [8510])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'B[0, 0]'])
            check_legs(['B[0, 0]', 365930]) # 2 * 5 * 23 * 37 * 43
            check_node_accesses(item, [365930])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'B[0, 0]'])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_epsilon, '_[0, 0]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_epsilon, '_[0, 0]'])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'B[0, 0]'])
            check_legs(['B[0, 0]', 365930]) # 2 * 5 * 23 * 37 * 43
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'B[0, 0]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'A[0, 1]'])
            check_legs(['A[0, 1]', 399970]) # 2 * 5 * 23 * 37 * 47
            check_node_accesses(item, [230, 399970])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'A[0, 1]'])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, item, [:before_alternative, prediction])
            # 12399070 = 2 * 5 * 23 * 37 * 47 * 31
            check_legs(['Alt(A => a .)[0, 1]', 12399070])
            check_node_accesses(item, [7130, 12399070])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'a[0, 1]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'a[0, 1]'])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'Alt(A => a .)[0, 1]'])
            # 12399070 = 2 * 5 * 23 * 37 * 47 * 31
            check_legs(['Alt(A => a .)[0, 1]', 12399070])
          end,
          lambda do |event, item|
            prediction = 'Alt(A => a .)[0, 1]'
            check_event(event, item, [:after_alternative, prediction])
          end,
          lambda do |event, item|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, item, [:before_alternative, prediction])
            # For prime factoring:
            # https://www.calculatorsoup.com/calculators/math/prime-factors.php
            check_legs(['Alt(A => B A .)[0, 1]', 399970]) # 2 * 5 * 23 * 37 * 47
            check_node_accesses(item, [8510, 399970])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, parent, [:before_subnodes, prediction])
            expect(children.size).to eq(2)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'B[0, 0]'])
            check_legs(['B[0, 0]', 17198710]) # 2 * 5 * 23 * 37 * 47 * 43
            check_node_accesses(item, [365930, 17198710])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'B[0, 0]'])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_epsilon, '_[0, 0]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_epsilon, '_[0, 0]'])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'B[0, 0]'])
            check_legs(['B[0, 0]', 17198710]) # 2 * 5 * 23 * 37 * 43 * 47
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'B[0, 0]'])
          end,
          lambda do |event, parent, _children|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, parent, [:after_subnodes, prediction])
            check_legs(['Alt(A => B A .)[0, 1]', 399970]) # 2 * 5 * 23 * 37 * 47
            check_node_accesses(parent, [8510, 399970])
          end,
          lambda do |event, item|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, item, [:after_alternative, prediction])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'A[0, 1]'])
            check_legs(['A[0, 1]', 399970]) # 2 * 5 * 23 * 37 * 47
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'A[0, 1]'])
          end,
          lambda do |event, parent, _children|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, parent, [:after_subnodes, prediction])
            check_legs(['Alt(A => B A .)[0, 1]', 8510]) # 2 * 5 * 23 * 37
          end,
          lambda do |event, item|
            prediction = 'Alt(A => B A .)[0, 1]'
            check_event(event, item, [:after_alternative, prediction])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'A[0, 1]'])
            check_legs(['A[0, 1]', 230]) # 2 * 5 * 23
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'A[0, 1]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_non_terminal, 'T[1, 4]'])
            check_legs(['T[1, 4]', 290]) # 2 * 5 * 29
            check_node_accesses(item, [66, 290])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:before_subnodes, 'T[1, 4]'])
            expect(children.size).to eq(3)
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[1, 2]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[1, 2]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[2, 3]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[2, 3]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:before_terminal, 'b[3, 4]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_terminal, 'b[3, 4]'])
          end,
          lambda do |event, parent, _children|
            check_event(event, parent, [:after_subnodes, 'T[1, 4]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'T[1, 4]'])
          end,
          lambda do |event, parent, children|
            prediction = 'Alt(S => A T .)[0, 4]'
            check_event(event, parent, [:after_subnodes, prediction])
            expect(children.size).to eq(2)
            check_legs(['Alt(S => A T .)[0, 4]', 10]) # 2 * 5
          end,
          lambda do |event, item|
            check_event(event, item, [:after_alternative, 'Alt(S => A T .)[0, 4]'])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:after_subnodes, 'S[0, 4]'])
            expect(children.size).to eq(2)
            check_legs(['S[0, 4]', 2]) # 2
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'S[0, 4]'])
          end,
          lambda do |event, parent, children|
            check_event(event, parent, [:after_subnodes, 'Phi[0, 4]'])
            expect(children.size).to eq(1)
          end,
          lambda do |event, item|
            check_event(event, item, [:after_non_terminal, 'Phi[0, 4]'])
          end,
          lambda do |event, item|
            check_event(event, item, [:after_pforest, grm_sppf_pforest1])
          end
        ]
        subject.start
      end
    end # context
  end # describe
end # module

# End of file
