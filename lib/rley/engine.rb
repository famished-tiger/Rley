require_relative './syntax/grammar_builder'
require_relative './parser/gfg_earley_parser'
require_relative './parse_tree_visitor'
require_relative './parse_forest_visitor'
require_relative './parse_rep/parse_tree_factory'
require_relative './parse_rep/parse_forest_factory'

module Rley # This module is used as a namespace
  # Configuration of an Rley::Engine instance.
  EngineConfig = Struct.new(
    # @!attribute [r] parse_repr
    #   Indicates how the parse result must represented
    #   @return [Symbol] allowed values are: :parse_tree, :parse_forest
    :parse_repr,
    :repr_builder,
    :diagnose
  ) do

    # Constructor with default initialization.
    def initialize()
      super()
      self.parse_repr = :parse_tree
      self.repr_builder = :default
      self.diagnose = false
    end
  end

  # Implementation of the GoF Facade design pattern.
  # An Engine object provides a higher-level interface that shields
  # Rley client code from the lower-level classes.
  class Engine
    # @!attribute [r] configuration
    # @return [EngineConfig] the engine's configuration 
    attr_reader :configuration
    
    # @!attribute [r] grammar
    # @return [Rley::Syntax::Grammar] the grammar of the language to parse    
    attr_reader :grammar

    # Constructor.
    # @example Produce a parse forest
    #   Engine.new do |config|
    #     config.parse_repr = :parse_forest
    #   end
    def initialize()
      @configuration = EngineConfig.new
      yield configuration if block_given?
    end

    # Factory method.
    # @param aBlock [Proc, Lambda] Code block for creating the grammar.
    # @return [Rley::Syntax::Grammar] the grammar of the language to parse.
    # @example Grammar for array of integers
    #   instance = Engine.new
    #   instance.build_grammar do
    #     add_terminals('LBRACKET', 'RBRACKET', 'COMMA', 'INTEGER')
    #     add_production('start' => 'array')    
    #     add_production('array' => 'LBRACKET elements RBRACKET')
    #     add_production('array' => 'LBRACKET RBRACKET')
    #     add_production('elements' => 'elements COMMA INTEGER')
    #     add_production('elements' => 'INTEGER')    
    #   end
    def build_grammar(&aBlock)
      builder = Rley::Syntax::GrammarBuilder.new(&aBlock)
      @grammar = builder.grammar
    end
    
    # Use the given grammar.
    # @param aGrammar [Rley::Syntax::Grammar]
    # @return [Rley::Syntax::Grammar] the grammar of the language to parse.
    def use_grammar(aGrammar)
      @grammar = aGrammar
    end

    # Parse the sequence of tokens produced by the given tokenizer object.
    # @param aTokenizer [#each]
    # @return [Parser::GFGParsing]
    def parse(aTokenizer)
      tokens = []
      aTokenizer.each do |a_token|
        next unless a_token
        term_name = a_token.terminal
        term_symb = grammar.name2symbol[term_name]
        a_token.instance_variable_set(:@terminal, term_symb)
        tokens << a_token
      end
      parser = build_parser(grammar)
      parser.gf_graph.diagnose if configuration.diagnose
      result = parser.parse(tokens)
      result.tidy_up!
      
      return result
    end

    # Convert raw parse result into a more convenient representation
    # (parse tree or parse forest) as specified by the configuration.
    # @param aRawParse [Parser::GFGParsing]
    # @return [Rley::PTree::ParseTree, Rley::SPPF::ParseForest]
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
    # @return [Rley::PTree::ParseTree]
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
    # @return [Rley::SPPF::ParseForest]
    def to_pforest(aRawParse)
      factory = ParseRep::ParseForestFactory.new(aRawParse)
      if configuration.repr_builder == :default
        result = factory.create(nil)
      else
        result = factory.create(configuration.repr_builder)
      end

      return result
    end

    # Build a visitor for the given parse tree
    # @param aPTree [PTree::ParseTree]
    # @return [ParseTreeVisitor]
    def ptree_visitor(aPTree)
      return ParseTreeVisitor.new(aPTree)
    end

    # Build a visitor for the given parse forest
    # @param aPForest [SPPF::ParseForest]
    # @return [ParseForestVisitor]
    def pforest_visitor(aPForest)
      return ParseForestVisitor.new(aPForest)
    end

    protected

    def build_parser(aGrammar)
      return Parser::GFGEarleyParser.new(aGrammar)
    end
  end # class
end # module
