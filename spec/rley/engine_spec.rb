# frozen_string_literal: true

require_relative '../spec_helper'


require_relative '../../lib/rley/lexical/token'
require_relative '../../lib/rley/parse_rep/cst_builder'

# Load the class under test
require_relative '../../lib/rley/engine'

module Rley # Open this namespace to avoid module qualifier prefixes
  describe Engine do
    subject(:an_engine) { described_class.new }

    context 'Creation and initialization:' do
      it 'is created without argument' do
        expect { described_class.new }.not_to raise_error
      end

      it 'is created with block argument' do
        expect do
          described_class.new do |config|
            config.parse_repr = :raw
          end
        end.not_to raise_error
      end

      it "doesn't have a link to a grammar yet" do
        expect(an_engine.grammar).to be_nil
      end
    end # context

    context 'Grammar building:' do
      it 'builds grammar' do
        an_engine.build_grammar do
          add_terminals('a', 'b', 'c')
          add_production('S' => 'A')
          add_production('A' => 'a A c')
          add_production('A' => 'b')
        end

        expect(an_engine.grammar).to be_a(Rley::Syntax::Grammar)
        expect(an_engine.grammar.rules.size).to eq(3)
      end
    end # context

    # rubocop: disable Lint/ConstantDefinitionInBlock
    class ABCTokenizer
      # Constructor
      def initialize(someText)
        @input = someText.dup
      end

      def each
        pos = Rley::Lexical::Position.new(1, 1) # Dummy position
        lexemes = @input.scan(/\S/)
        lexemes.each do |ch|
          if ch =~ /[abc]/
            yield Rley::Lexical::Token.new(ch, ch, pos)
          else
             raise StandardError, "Invalid character #{ch}"
          end
        end
      end
    end # class
    # rubocop: enable Lint/ConstantDefinitionInBlock

    # Utility method. Ensure that the engine
    # has the defnition of a sample grammar
    def add_sample_grammar(anEngine)
      anEngine.build_grammar do
        add_terminals('a', 'b', 'c')
        add_production('S' => 'A')
        add_production('A' => 'a A c')
        add_production('A' => 'b')
      end
    end

    context 'Parsing:' do
      subject(:an_engine) do
        instance = described_class.new
        add_sample_grammar(instance)
        instance
      end

      it 'parses a stream of tokens' do
        sample_text = 'a a b c c'
        tokenizer = ABCTokenizer.new(sample_text)
        result = an_engine.parse(tokenizer)
        expect(result).to be_success
      end
    end # context

    context 'Parse tree manipulation:' do
      let(:sample_tokenizer) do
        sample_text = 'a a b c c'
        ABCTokenizer.new(sample_text)
      end

      subject(:an_engine) do
        instance = described_class.new
        add_sample_grammar(instance)
        instance
      end

      it 'builds a parse tree even for a nullable production' do
        instance = described_class.new
        instance.build_grammar do
          add_terminals('a', 'b', 'c')
          add_production 'S' => 'A BC'
          add_production 'A' => 'a'
          add_production 'BC' => 'B_opt C_opt'
          add_production 'B_opt' => 'b'
          add_production 'B_opt' => []
          add_production 'C_opt' => 'c'
          add_production 'C_opt' => []
        end
        input = ABCTokenizer.new('a')
        raw_result = instance.parse(input)
        expect { instance.to_ptree(raw_result) }.not_to raise_error
      end

      it 'builds default parse trees' do
        raw_result = an_engine.parse(sample_tokenizer)
        ptree = an_engine.convert(raw_result)
        expect(ptree).to be_a(PTree::ParseTree)
      end

      it 'builds custom parse trees' do
        # Cheating: we point to default tree builder (CST)
        an_engine.configuration.repr_builder = ParseRep::CSTBuilder
        raw_result = an_engine.parse(sample_tokenizer)
        ptree = an_engine.convert(raw_result)
        expect(ptree).to be_a(PTree::ParseTree)
      end

      it 'provides a parse visitor' do
        raw_result = an_engine.parse(sample_tokenizer)
        ptree = an_engine.to_ptree(raw_result)
        visitor = an_engine.ptree_visitor(ptree)
        expect(visitor).to be_a(ParseTreeVisitor)
      end
    end # context

    context 'Parse forest manipulation:' do
      subject(:an_engine) do
        instance = described_class.new
        add_sample_grammar(instance)
        instance
      end

      let(:sample_tokenizer) do
        sample_text = 'a a b c c'
        ABCTokenizer.new(sample_text)
      end

      it 'builds a parse forest even for a nullable production' do
        instance = described_class.new
        instance.build_grammar do
          add_terminals('a', 'b', 'c')
          add_production 'S' => 'A BC'
          add_production 'A' => 'a'
          add_production 'BC' => 'B_opt C_opt'
          add_production 'B_opt' => 'b'
          add_production 'B_opt' => []
          add_production 'C_opt' => 'c'
          add_production 'C_opt' => []
        end
        input = ABCTokenizer.new('a')
        raw_result = instance.parse(input)
        expect { instance.to_pforest(raw_result) }.not_to raise_error
      end

      it 'builds parse forest' do
        raw_result = an_engine.parse(sample_tokenizer)
        pforest = an_engine.to_pforest(raw_result)
        expect(pforest).to be_a(SPPF::ParseForest)
      end

      it 'provides a parse visitor' do
        raw_result = an_engine.parse(sample_tokenizer)
        ptree = an_engine.to_pforest(raw_result)
        visitor = an_engine.pforest_visitor(ptree)
        expect(visitor).to be_a(ParseForestVisitor)
      end
    end # context
  end # describe
end # module
