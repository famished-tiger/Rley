require_relative './syntax/grammar_builder'
require_relative './parser/gfg_earley_parser'
require_relative './parse_rep/parse_tree_factory'

module Rley # This module is used as a namespace
  EngineConfig = Struct.new(
    :parse_repr,
    :repr_builder
  ) do
    def initialize()
      super()
      self.parse_repr = :parse_tree
      self.repr_builder = :default
    end
  end

  # Implementation of the GoF Facade design pattern.
  # an Engine object provides a higher-level interface that shields
  # Rley client code from the lower-level classes.
  class Engine
    attr_reader :configuration
    attr_reader :grammar

    # Constructor.
    # @param &aBlock [Proc, Lambda] Code block for setting the configuration.
    def initialize(&aConfigBlock)
      @configuration = EngineConfig.new

       yield configuration if block_given?
    end

    # Factory method.
    # @param &aBlock [Proc, Lambda] Code block for creating the grammar.
    def build_grammar(&aBlock)
      builder = Rley::Syntax::GrammarBuilder.new(&aBlock)
      @grammar = builder.grammar
    end
    
    # Use the given grammar.
    # @param aGrammar [Rley::Syntax::Grammar]
    def use_grammar(aGrammar)
      @grammar = aGrammar
    end

    # Parse the sequence of tokens produced by the given tokenizer object.
    # @param aTokenizer [#each]
    # @return [Parser::GFGParsing]
    def parse(aTokenizer)
      tokens = []
      aTokenizer.each do |a_token|
        if a_token
          term_name = a_token.terminal
          term_symb = grammar.name2symbol[term_name]
          a_token.instance_variable_set(:@terminal, term_symb)
          tokens << a_token
        end
      end
      parser = build_parser(grammar)
      return parser.parse(tokens)
    end

    # Convert raw parse result into a more convenient representation
    # (parse tree or parse forest) as specified by the configuration.
    # @param aRawParse [Parser::GFGParsing]
    def convert(aRawParse)
      result = case configuration.parse_repr
                 when :parse_tree
                   to_ptree(aRawParse)
                 when :parse_forest
                   to_pforest(aRawParse)
               end

      return result
    end

    # Convert raw parse result into a parse tree representation
    # @param aRawParse [Parser::GFGParsing]
    def to_ptree(aRawParse)
      factory = ParseRep::ParseTreeFactory.new(aRawParse)
      if configuration.repr_builder == :default
        result = factory.create(nil)
      else
        result = factory.create(configuration.repr_builder)
      end

      return result
    end

    # Convert raw parse result into a parse forest representation
    # @param aRawParse [Parser::GFGParsing]
    # def to_pforest(aRawParse)
      # factory = ParseRep::ParseForestFactory.new(aRawParse)
      # if configuration.repr_builder == :default
        # result = factory.create(nil)
      # else
        # result = factory.create(configuration.repr_builder)
      # end

      # return result
    # end

    # Build a visitor for the given parse tree
    # @param aPTree[PTree::ParseTree]
    # @return [ParseTreeVisitor]
    def ptree_visitor(aPTree)
      return Rley::ParseTreeVisitor.new(aPTree)
    end

    # @param aPTree[SPPF::ParseForest]
    # @return [ParseForestVisitor]
    # def pforest_visitor(aPForest)
      # return Rley::ParseForestVisitor.new(aPForest)
    # end

    protected

    def build_parser(aGrammar)
      return Parser::GFGEarleyParser.new(aGrammar)
    end
  end # class
end # module

