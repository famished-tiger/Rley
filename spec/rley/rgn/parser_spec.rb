# frozen_string_literal: true

require_relative '../../spec_helper' # Use the RSpec framework

require_relative '../../../lib/rley/rgn/ast_builder'
# Load the class under test
require_relative '../../../lib/rley/rgn/parser'

module Rley
  module RGN
    describe Parser do
      subject { Parser.new }

      # Utility method to walk towards deeply nested node
      # @param aNTNode [Rley::PTree::NonTerminalNode]
      # @param subnodePath[Array<Integer>] An Array of subnode indices
      def walk_subnodes(aNTNode, subnodePath)
        curr_node = aNTNode
        subnodePath.each do |index|
          curr_node = curr_node.subnodes[index]
        end

        curr_node
      end

      context 'Initialization:' do
        it 'should be initialized without argument' do
          expect { Parser.new }.not_to raise_error
        end

        it 'should have its parse engine initialized' do
          expect(subject.engine).to be_kind_of(Rley::Engine)
        end
      end # context

      context 'Parsing into CST:' do
        subject do
          instance = Parser.new
          instance.engine.configuration.repr_builder = Rley::ParseRep::CSTBuilder

          instance
        end

        it 'should parse single symbol names' do
          samples = %w[IF ifCondition statement]

          # One drawback of CSTs: they have a deeply nested structure
          samples.each do |source|
            ptree = subject.parse(source)
            expect(ptree.root).to be_kind_of(Rley::PTree::NonTerminalNode)
            expect(ptree.root.symbol.name).to eq('notation')
            expect(ptree.root.subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
            expect(ptree.root.subnodes[0].symbol.name).to eq('rhs')
            expect(ptree.root.subnodes[0].subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
            member_seq = ptree.root.subnodes[0].subnodes[0]
            expect(member_seq.symbol.name).to eq('member_seq')
            expect(member_seq.subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
            expect(member_seq.subnodes[0].symbol.name).to eq('member')
            expect(member_seq.subnodes[0].subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
            expect(member_seq.subnodes[0].subnodes[0].symbol.name).to eq('strait_member')
            strait_member = member_seq.subnodes[0].subnodes[0]
            expect(strait_member.subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
            expect(strait_member.subnodes[0].symbol.name).to eq('base_member')
            expect(strait_member.subnodes[0].subnodes[0]).to be_kind_of(Rley::PTree::TerminalNode)
            expect(strait_member.subnodes[0].subnodes[0].token.lexeme).to eq(source)
          end
        end
      end # context

      context 'Parsing into AST:' do
        subject do
          instance = Parser.new
          instance.engine.configuration.repr_builder = ASTBuilder

          instance
        end

        it 'should parse single symbol names' do
          samples = %w[IF ifCondition statement]

          samples.each do |source|
            ptree = subject.parse(source)
            expect(ptree.root).to be_kind_of(SymbolNode)
            expect(ptree.root.name).to eq(source)
            expect(ptree.root.annotation).to be_empty
          end
        end

        it 'should parse a sequence of symbols' do
          sequence = 'INT_LIT ELLIPSIS INT_LIT'

          ptree = subject.parse(sequence)
          expect(ptree.root).to be_kind_of(SequenceNode)
          expect(ptree.root.subnodes[0]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[0].name).to eq('INT_LIT')
          expect(ptree.root.subnodes[1]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[1].name).to eq('ELLIPSIS')
          expect(ptree.root.subnodes[2]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[2].name).to eq('INT_LIT')
        end

        it 'should parse an optional symbol' do
          optional = 'member_seq?'

          ptree = subject.parse(optional)
          expect(ptree.root).to be_kind_of(RepetitionNode)
          expect(ptree.root.name).to eq('rep_member_seq_qmark')
          expect(ptree.root.child).to be_kind_of(SymbolNode)
          expect(ptree.root.child.name).to eq('member_seq')
          expect(ptree.root.repetition).to eq(:zero_or_one)
        end

        it 'should parse a symbol with a + modifier' do
          one_or_more = 'member+'

          ptree = subject.parse(one_or_more)
          expect(ptree.root).to be_kind_of(RepetitionNode)
          expect(ptree.root.name).to eq('rep_member_plus')
          expect(ptree.root.child).to be_kind_of(SymbolNode)
          expect(ptree.root.child.name).to eq('member')
          expect(ptree.root.repetition).to eq(:one_or_more)
        end

        it 'should parse a symbol with a * modifier' do
          zero_or_more = 'declaration* EOF'

          ptree = subject.parse(zero_or_more)
          expect(ptree.root).to be_kind_of(SequenceNode)
          expect(ptree.root.name).to eq('seq_rep_declaration_star_EOF')
          expect(ptree.root.subnodes[0]).to be_kind_of(RepetitionNode)
          expect(ptree.root.subnodes[0].name).to eq('rep_declaration_star')
          expect(ptree.root.subnodes[0].repetition).to eq(:zero_or_more)
          expect(ptree.root.subnodes[0].child).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[0].child.name).to eq('declaration')
          expect(ptree.root.subnodes[1]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[1].name).to eq('EOF')
        end

        it 'should parse a grouping with a modifier' do
          input = 'IF ifCondition statement (ELSE statement)?'

          ptree = subject.parse(input)
          expect(ptree.root).to be_kind_of(SequenceNode)
          expect(ptree.root.subnodes[0]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[0].name).to eq('IF')
          expect(ptree.root.subnodes[1]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[1].name).to eq('ifCondition')
          expect(ptree.root.subnodes[2]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[2].name).to eq('statement')
          expect(ptree.root.subnodes[3]).to be_kind_of(RepetitionNode)
          expect(ptree.root.subnodes[3].name).to eq('rep_seq_ELSE_statement_qmark')
          expect(ptree.root.subnodes[3].repetition).to eq(:zero_or_one)
          expect(ptree.root.subnodes[3].child).to be_kind_of(SequenceNode)
          expect(ptree.root.subnodes[3].child.subnodes[0]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[3].child.subnodes[0].name).to eq('ELSE')
          expect(ptree.root.subnodes[3].child.subnodes[1]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[3].child.subnodes[1].name).to eq('statement')
        end

        it 'should parse an annotated symbol' do
          optional = 'member_seq{repeat: 0..1}'

          ptree = subject.parse(optional)
          expect(ptree.root).to be_kind_of(RepetitionNode)
          expect(ptree.root.name).to eq('rep_member_seq_qmark')
          expect(ptree.root.repetition).to eq(:zero_or_one)
          expect(ptree.root.child).to be_kind_of(SymbolNode)
          expect(ptree.root.child.name).to eq('member_seq')
        end

        it 'should parse a grouping with embedded annotation' do
          if_stmt = "IF ifCondition statement ( ELSE { match_closest: 'IF' } statement )?"

          ptree = subject.parse(if_stmt)
          expect(ptree.root).to be_kind_of(SequenceNode)
          expect(ptree.root.subnodes[0]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[0].name).to eq('IF')
          expect(ptree.root.subnodes[1]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[1].name).to eq('ifCondition')
          expect(ptree.root.subnodes[2]).to be_kind_of(SymbolNode)
          expect(ptree.root.subnodes[2].name).to eq('statement')
          optional = ptree.root.subnodes[3]
          expect(optional).to be_kind_of(RepetitionNode)
          expect(optional.name).to eq('rep_seq_ELSE_statement_qmark')
          expect(optional.repetition).to eq(:zero_or_one)
          expect(optional.child).to be_kind_of(SequenceNode)
          expect(optional.child.subnodes[0]).to be_kind_of(SymbolNode)
          expect(optional.child.subnodes[0].name).to eq('ELSE')
          expect(optional.child.subnodes[0].annotation).to eq({ 'match_closest' => 'IF' })
          expect(optional.child.subnodes[1].name).to eq('statement')
        end
      end # context
    end # describe
  end # module
end # module
