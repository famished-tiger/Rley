# frozen_string_literal: true

require_relative '../spec_helper'

require_relative '../../lib/rley/lexical/token'
require_relative '../../lib/rley/parser/gfg_earley_parser'
require_relative '../../lib/rley/engine'
require_relative './support/grammar_abc_helper'
require_relative './support/grammar_sppf_helper'
# Load the class under test
require_relative '../../lib/rley/parse_tree_visitor'

module Rley # Open this namespace to avoid module qualifier prefixes
  describe ParseTreeVisitor do
    let(:grammar_abc) do
      sandbox = Object.new
      sandbox.extend(GrammarABCHelper)
      builder = sandbox.grammar_abc_builder
      builder.grammar
    end

    # Default instantiation rule
    subject(:ptree_visitor) { described_class.new(grm_abc_ptree1) }

    let(:a_) { grammar_abc.name2symbol['a'] }
    let(:b_) { grammar_abc.name2symbol['b'] }
    let(:c_) { grammar_abc.name2symbol['c'] }

    # Helper method that mimicks the output of a tokenizer
    # for the language specified by grammar_abc
    let(:grm_abc_tokens1) do
      pos = Lexical::Position.new(1, 2) # Dummy position
      %w[a a b c c].map { |ch| Lexical::Token.new(ch, ch, pos) }
    end

    # Factory method that builds a sample parse tree.
    # Generated tree has the following structure:
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
    let(:grm_abc_ptree1) do
      engine = Rley::Engine.new
      engine.use_grammar(grammar_abc)
      parse_result = engine.parse(grm_abc_tokens1)
      ptree = engine.convert(parse_result)
      ptree
    end

    context 'Standard creation & initialization:' do
      it 'is initialized with a parse tree argument' do
        expect { described_class.new(grm_abc_ptree1) }.not_to raise_error
      end

      it 'knows the parse tree to visit' do
        expect(ptree_visitor.ptree).to eq(grm_abc_ptree1)
      end

      it "doesn't have subscribers at start" do
        expect(ptree_visitor.subscribers).to be_empty
      end
    end # context


    context 'Subscribing:' do
      let(:listener1) { double('fake-subscriber1') }
      let(:listener2) { double('fake-subscriber2') }

      it 'allows subscriptions' do
        ptree_visitor.subscribe(listener1)
        expect(ptree_visitor.subscribers.size).to eq(1)
        expect(ptree_visitor.subscribers).to eq([listener1])

        ptree_visitor.subscribe(listener2)
        expect(ptree_visitor.subscribers.size).to eq(2)
        expect(ptree_visitor.subscribers).to eq([listener1, listener2])
      end

      it 'allows un-subcriptions' do
        ptree_visitor.subscribe(listener1)
        ptree_visitor.subscribe(listener2)
        ptree_visitor.unsubscribe(listener2)
        expect(ptree_visitor.subscribers.size).to eq(1)
        expect(ptree_visitor.subscribers).to eq([listener1])
        ptree_visitor.unsubscribe(listener1)
        expect(ptree_visitor.subscribers).to be_empty
      end
    end # context


    context 'Notifying visit events:' do
      # Default instantiation rule
      subject(:ptree_visitor) do
        instance = described_class.new(grm_abc_ptree1)
        instance.subscribe(listener1)
        instance
      end

      # Use doubles/mocks to simulate formatters
      let(:listener1) { double('fake-subscriber1') }
      let(:listener2) { double('fake-subscriber2') }

      # Sample non-terminal node
      let(:nterm_node) do
        first_big_a = grm_abc_ptree1.root.subnodes[0]
        second_big_a = first_big_a.subnodes[1]
        second_big_a.subnodes[1]
      end

      # Sample terminal node
      let(:term_node) { nterm_node.subnodes[0] }

      it 'reacts to the start_visit_ptree message' do
        # Notify subscribers when start the visit of the ptree
        expect(listener1).to receive(:before_ptree).with(grm_abc_ptree1)
        ptree_visitor.start_visit_ptree(grm_abc_ptree1)
      end

      it 'reacts to the start_visit_nonterminal message' do
        # Notify subscribers when start the visit of a non-terminal node
        expect(listener1).to receive(:before_non_terminal).with(nterm_node)
        ptree_visitor.visit_nonterminal(nterm_node)
      end

      it 'reacts to the visit_children message' do
        # Notify subscribers when start the visit of children nodes
        children = nterm_node.subnodes
        args = [nterm_node, children]
        expect(listener1).to receive(:before_subnodes).with(*args)
        expect(listener1).to receive(:before_terminal).with(children[0])
        expect(listener1).to receive(:after_terminal).with(children[0])
        expect(listener1).to receive(:after_subnodes).with(nterm_node, children)
        ptree_visitor.send(:traverse_subnodes, nterm_node)
      end

      it 'reacts to the end_visit_nonterminal message' do
        # Notify subscribers when ending the visit of a non-terminal node
        expect(listener1).to receive(:after_non_terminal).with(nterm_node)
        ptree_visitor.end_visit_nonterminal(nterm_node)
      end

      it 'reacts to the visit_terminal message' do
        # Notify subscribers when start & ending the visit of a terminal node
        expect(listener1).to receive(:before_terminal).with(term_node)
        expect(listener1).to receive(:after_terminal).with(term_node)
        ptree_visitor.visit_terminal(term_node)
      end

      it 'reacts to the end_visit_ptree message' do
        # Notify subscribers when ending the visit of the ptree
        expect(listener1).to receive(:after_ptree).with(grm_abc_ptree1)
        ptree_visitor.end_visit_ptree(grm_abc_ptree1)
      end

      # rubocop: disable Naming/VariableNumber
      it 'begins the visit when requested' do
        # Reminder: parse tree structure is
        # S[0,5]
        # +- A[0,5]
        #    +- a[0,0]
        #    +- A[1,4]
        #    |  +- a[1,1]
        #    |  +- A[2,3]
        #    |  |  +- b[2,3]
        #    |  +- c[3,4]
        #    +- c[4,5]
        root = grm_abc_ptree1.root
        children = root.subnodes
        big_a_1 = children[0]
        big_a_1_children = big_a_1.subnodes
        big_a_2 = big_a_1_children[1]
        big_a_2_children = big_a_2.subnodes
        big_a_3 = big_a_2_children[1]
        big_a_3_children = big_a_3.subnodes
        expectations = [
          [:before_ptree, [grm_abc_ptree1]],
          [:before_non_terminal, [root]],
          [:before_subnodes, [root, children]],
          [:before_non_terminal, [big_a_1]],
          [:before_subnodes, [big_a_1, big_a_1_children]],
          [:before_terminal, [big_a_1_children[0]]],
          [:after_terminal, [big_a_1_children[0]]],
          [:before_non_terminal, [big_a_2]],
          [:before_subnodes, [big_a_2, big_a_2_children]],
          [:before_terminal, [big_a_2_children[0]]],
          [:after_terminal, [big_a_2_children[0]]],
          [:before_non_terminal, [big_a_3]],
          [:before_subnodes, [big_a_3, big_a_3_children]],
          [:before_terminal, [big_a_3_children[0]]],
          [:after_terminal, [big_a_3_children[0]]],
          [:after_subnodes, [big_a_3, big_a_3_children]],
          [:before_terminal, [big_a_2_children[2]]],
          [:after_terminal, [big_a_2_children[2]]],
          [:after_subnodes, [big_a_2, big_a_2_children]],
          [:before_terminal, [big_a_1_children[2]]],
          [:after_terminal, [big_a_1_children[2]]],
          [:after_subnodes, [big_a_1, big_a_1_children]],
          [:after_subnodes, [root, children]],
          [:after_ptree, [grm_abc_ptree1]]
        ]
        expectations.each do |(msg, args)|
          expect(listener1).to receive(msg).with(*args).ordered
        end

        # Here we go...
        ptree_visitor.start
      end

      it 'also visits in pre-order' do
        # Reminder: parse tree structure is
        # S[0,5]
        # +- A[0,5]
        #    +- a[0,0]
        #    +- A[1,4]
        #    |  +- a[1,1]
        #    |  +- A[2,3]
        #    |  |  +- b[2,3]
        #    |  +- c[3,4]
        #    +- c[4,5]
        root = grm_abc_ptree1.root
        # Here we defeat encapsulation for the good cause
        ptree_visitor.instance_variable_set(:@traversal, :pre_order)

        children = root.subnodes
        big_a_1 = children[0]
        big_a_1_children = big_a_1.subnodes
        big_a_2 = big_a_1_children[1]
        big_a_2_children = big_a_2.subnodes
        big_a_3 = big_a_2_children[1]
        big_a_3_children = big_a_3.subnodes
        expectations = [
          [:before_ptree, [grm_abc_ptree1]]
          # TODO: fix this test
          # [:before_subnodes, [root, children]],
          # [:before_non_terminal, [root]],

          # [:before_non_terminal, [big_a_1]],
          # [:before_subnodes, [big_a_1, big_a_1_children]],
          # [:before_terminal, [big_a_1_children[0]]],
          # [:after_terminal, [big_a_1_children[0]]],
          # [:before_non_terminal, [big_a_2]],
          # [:before_subnodes, [big_a_2, big_a_2_children]],
          # [:before_terminal, [big_a_2_children[0]]],
          # [:after_terminal, [big_a_2_children[0]]],
          # [:before_non_terminal, [big_a_3]],
          # [:before_subnodes, [big_a_3, big_a_3_children]],
          # [:before_terminal, [big_a_3_children[0]]],
          # [:after_terminal, [big_a_3_children[0]]],
          # [:after_subnodes, [big_a_3, big_a_3_children]],
          # [:before_terminal, [big_a_2_children[2]]],
          # [:after_terminal, [big_a_2_children[2]]],
          # [:after_subnodes, [big_a_2, big_a_2_children]],
          # [:before_terminal, [big_a_1_children[2]]],
          # [:after_terminal, [big_a_1_children[2]]],
          # [:after_subnodes, [big_a_1, big_a_1_children]],
          # [:after_subnodes, [root, children]],
          # [:after_ptree, [grm_abc_ptree1]]
        ]
        expectations.each do |(msg, args)|
          expect(listener1).to receive(msg).with(*args).ordered
        end

        # Here we go...
        ptree_visitor.start
      end
      # rubocop: enable Naming/VariableNumber
    end # context
  end # describe
end # module

# End of file
