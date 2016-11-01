require_relative '../spec_helper'

require_relative './support/grammar_helper'
require_relative './support/grammar_sppf_helper'
require_relative '../../lib/rley/parser/token'
require_relative '../../lib/rley/parser/gfg_earley_parser'
require_relative '../../lib/rley/sppf/non_terminal_node'
require_relative '../../lib/rley/sppf/parse_forest'

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
      build_token_sequence(%w(a b b b), grammar_sppf)
    end

    # A forest with just a root node
    let(:rooted_forest) do
      parser = Parser::GFGEarleyParser.new(grammar_sppf)
      parse_result = parser.parse(sample_tokens)
      accepting_entry = parse_result.accepting_entry
      full_range = { low: 0, high: parse_result.chart.last_index }
      root_node = create_non_terminal_node(accepting_entry, full_range)
      Rley::SPPF::ParseForest.new(root_node)
    end

=begin
    # Factory method that builds a sample parse forest.
    # Generated forest has the following structure:
    # S[0,5]
    # +- A[0,5]
    #    +- a[0,0]
    #    +- A[1,4]
    #    |  +- a[1,1]
    #    |  +- A[2,3]
    #    |  |  +- b[2,3]
    #    |  +- c[3,4]
    #    +- c[4,5]
    # Capital letters represent non-terminal nodes
    let(:grm_abc_pforest1) do
      parser = Parser::EarleyParser.new(grammar_abc)
      parse_result = parser.parse(grm_abc_tokens1)
      parse_result.parse_forest
    end
=end

    # Default instantiation rule
    subject { ParseForestVisitor.new(rooted_forest) }


    context 'Standard creation & initialization:' do
      it 'should be initialized with a parse forest argument' do
        expect { ParseForestVisitor.new(rooted_forest) }.not_to raise_error
      end

      it 'should know the parse forest to visit' do
        expect(subject.pforest).to eq(rooted_forest)
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


    context 'Notifying visit events:' do
      # Use doubles/mocks to simulate subscribers
      let(:listener1) { double('fake-subscriber1') }
      let(:listener2) { double('fake-subscriber2') }

      it 'should react to the start_visit_pforest message' do
        subject.subscribe(listener1)

        # Notify subscribers when start the visit of the pforest
        expect(listener1).to receive(:before_pforest).with(rooted_forest)
        subject.start_visit_pforest(rooted_forest)
      end
=begin
      # Default instantiation rule
      subject do
        instance = ParseForestVisitor.new(grm_abc_pforest1)
        instance.subscribe(listener1)
        instance
      end



      # Sample non-terminal node
      let(:nterm_node) do
        first_big_a = grm_abc_pforest1.root.children[0]
        second_big_a = first_big_a.children[1]
        second_big_a.children[1]
      end

      # Sample terminal node
      let(:term_node) { nterm_node.children[0] }

      it 'should react to the start_visit_pforest message' do
        # Notify subscribers when start the visit of the pforest
        expect(listener1).to receive(:before_pforest).with(grm_abc_pforest1)
        subject.start_visit_pforest(grm_abc_pforest1)
      end

      it 'should react to the start_visit_nonterminal message' do
        # Notify subscribers when start the visit of a non-terminal node
        expect(listener1).to receive(:before_non_terminal).with(nterm_node)
        subject.visit_nonterminal(nterm_node)
      end

      it 'should react to the visit_children message' do
        # Notify subscribers when start the visit of children nodes
        children = nterm_node.children
        args = [nterm_node, children]
        expect(listener1).to receive(:before_children).with(*args)
        expect(listener1).to receive(:before_terminal).with(children[0])
        expect(listener1).to receive(:after_terminal).with(children[0])
        expect(listener1).to receive(:after_children).with(nterm_node, children)
        subject.send(:traverse_children, nterm_node)
      end

      it 'should react to the end_visit_nonterminal message' do
        # Notify subscribers when ending the visit of a non-terminal node
        expect(listener1).to receive(:after_non_terminal).with(nterm_node)
        subject.end_visit_nonterminal(nterm_node)
      end

      it 'should react to the visit_terminal message' do
        # Notify subscribers when start & ending the visit of a terminal node
        expect(listener1).to receive(:before_terminal).with(term_node)
        expect(listener1).to receive(:after_terminal).with(term_node)
        subject.visit_terminal(term_node)
      end

      it 'should react to the end_visit_pforest message' do
        # Notify subscribers when ending the visit of the pforest
        expect(listener1).to receive(:after_pforest).with(grm_abc_pforest1)
        subject.end_visit_pforest(grm_abc_pforest1)
      end

      it 'should begin the visit when requested' do
        # Reminder: parse forest structure is
        # S[0,5]
        # +- A[0,5]
        #    +- a[0,0]
        #    +- A[1,4]
        #    |  +- a[1,1]
        #    |  +- A[2,3]
        #    |  |  +- b[2,3]
        #    |  +- c[3,4]
        #    +- c[4,5]
        root = grm_abc_pforest1.root
        children = root.children
        big_a_1 = children[0]
        big_a_1_children = big_a_1.children
        big_a_2 = big_a_1_children[1]
        big_a_2_children = big_a_2.children
        big_a_3 = big_a_2_children[1]
        big_a_3_children = big_a_3.children
        expectations = [
          [:before_pforest, [grm_abc_pforest1]],
          [:before_non_terminal, [root]],
          [:before_children, [root, children]],
          [:before_non_terminal, [big_a_1]],
          [:before_children, [big_a_1, big_a_1_children]],
          [:before_terminal, [big_a_1_children[0]]],
          [:after_terminal, [big_a_1_children[0]]],
          [:before_non_terminal, [big_a_2]],
          [:before_children, [big_a_2, big_a_2_children]],
          [:before_terminal, [big_a_2_children[0]]],
          [:after_terminal, [big_a_2_children[0]]],
          [:before_non_terminal, [big_a_3]],
          [:before_children, [big_a_3, big_a_3_children]],
          [:before_terminal, [big_a_3_children[0]]],
          [:after_terminal, [big_a_3_children[0]]],
          [:after_children, [big_a_3, big_a_3_children]],
          [:before_terminal, [big_a_2_children[2]]],
          [:after_terminal, [big_a_2_children[2]]],
          [:after_children, [big_a_2, big_a_2_children]],
          [:before_terminal, [big_a_1_children[2]]],
          [:after_terminal, [big_a_1_children[2]]],
          [:after_children, [big_a_1, big_a_1_children]],
          [:after_children, [root, children]],
          [:after_pforest, [grm_abc_pforest1]]
        ]
        expectations.each do |(msg, args)|
          expect(listener1).to receive(msg).with(*args).ordered
        end

        # Here we go...
        subject.start
      end
=end
    end # context
  end # describe
end # module

# End of file
