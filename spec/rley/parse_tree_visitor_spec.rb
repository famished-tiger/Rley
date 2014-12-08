require_relative '../spec_helper'

require_relative '../../lib/rley/syntax/grammar_builder'
require_relative '../../lib/rley/parser/token'
require_relative '../../lib/rley/parser/earley_parser'
# Load the class under test
require_relative '../../lib/rley/parse_tree_visitor'

module Rley # Open this namespace to avoid module qualifier prefixes
  describe ParseTreeVisitor do
    let(:grammar_abc) do
      builder = Syntax::GrammarBuilder.new
      builder.add_terminals('a', 'b', 'c')
      builder.add_production('S' => ['A'])
      builder.add_production('A' => %w(a A c))
      builder.add_production('A' => ['b'])
      builder.grammar
    end

    let(:a_) { grammar_abc.name2symbol['a'] }
    let(:b_) { grammar_abc.name2symbol['b'] }
    let(:c_) { grammar_abc.name2symbol['c'] }


    # Helper method that mimicks the output of a tokenizer
    # for the language specified by gramma_abc
    let(:grm_abc_tokens1) do
      [
        Parser::Token.new('a', a_),
        Parser::Token.new('a', a_),
        Parser::Token.new('b', b_),
        Parser::Token.new('c', c_),
        Parser::Token.new('c', c_)
      ]
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
      parser = Parser::EarleyParser.new(grammar_abc)
      parse_result = parser.parse(grm_abc_tokens1)
      parse_result.parse_tree
    end


    # Default instantiation rule
    subject { ParseTreeVisitor.new(grm_abc_ptree1) }


    context 'Standard creation & initialization:' do

      it 'should be initialized with a parse tree argument' do
        expect { ParseTreeVisitor.new(grm_abc_ptree1) }.not_to raise_error
      end

      it 'should know the parse tree to visit' do
        expect(subject.ptree).to eq(grm_abc_ptree1)
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
      # Default instantiation rule
      subject do
        instance = ParseTreeVisitor.new(grm_abc_ptree1)
        instance.subscribe(listener1)
        instance
      end

      # Use doubles/mocks to simulate formatters
      let(:listener1) { double('fake-subscriber1') }
      let(:listener2) { double('fake-subscriber2') }
      
      # Sample non-terminal node
      let(:nterm_node) do 
        first_big_a = grm_abc_ptree1.root.children[0]
        second_big_a = first_big_a.children[1]
        second_big_a.children[1]
      end
      
      # Sample terminal node
      let(:term_node) { nterm_node.children[0] }     

      it 'should react to the start_visit_ptree message' do
        # Notify subscribers when start the visit of the ptree
        expect(listener1).to receive(:before_ptree).with(grm_abc_ptree1)
        subject.start_visit_ptree(grm_abc_ptree1)
      end
      
      it 'should react to the start_visit_nonterminal message' do
        # Notify subscribers when start the visit of a non-terminal node
        expect(listener1).to receive(:before_non_terminal).with(nterm_node)
        subject.start_visit_nonterminal(nterm_node)
      end

      it 'should react to the visit_children message' do
        # Notify subscribers when start the visit of children nodes
        children = nterm_node.children
        expect(listener1).to receive(:before_children).with(nterm_node, children)
        expect(listener1).to receive(:before_terminal).with(children[0])
        expect(listener1).to receive(:after_terminal).with(children[0])
        expect(listener1).to receive(:after_children).with(nterm_node, children)
        subject.visit_children(nterm_node)
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
      
      it 'should react to the end_visit_ptree message' do
        # Notify subscribers when ending the visit of the ptree
        expect(listener1).to receive(:after_ptree).with(grm_abc_ptree1)
        subject.end_visit_ptree(grm_abc_ptree1)
      end
      
      it 'should begin the visit when requested' do
        subject.start
      end

    end # context
  end # describe
end # module

# End of file
