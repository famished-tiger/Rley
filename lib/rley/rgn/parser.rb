# frozen_string_literal: true

require_relative 'tokenizer'
require_relative 'grammar'
require_relative 'ast_builder'

module Rley
  module RGN
    # A RRN (Rley Rule Notation) parser that produce concrete parse trees.
    # Concrete parse trees are the default kind of parse tree
    # generated by the Rley library.
    # They consist of two node types only:
    # - NonTerminalNode
    # - TerminalNode
    # A NonTerminalNode has zero or more child nodes (called subnodes)
    # A TerminalNode is leaf node, that is, it has no child node.
    # While concrete parse tree nodes can be generated out of the box,
    # they have the following drawbacks:
    # - Generic node classes that aren't always suited for the needs of
    #     the language being processing.
    # - Concrete parse tree tend to be deeply nested, which may complicate
    #   further processing.
    class Parser
      # @return [Rley::Engine] A facade object for the Rley parsing library
      attr_reader(:engine)

      def initialize
        # Create a Rley facade object
        @engine = Rley::Engine.new do |cfg|
          cfg.diagnose = true
          cfg.repr_builder = RGN::ASTBuilder
        end

        # Step 1. Load RGN grammar
        @engine.use_grammar(Rley::RGN::RGNGrammar)
      end

      # Parse the given RGN snippet into a parse tree.
      # @param source [String] Snippet to parse
      # @return [Rley::ParseTree] A parse tree equivalent to the RGN input.
      def parse(source)
        lexer = Tokenizer.new(source)
        result = engine.parse(lexer.tokens)

        unless result.success?
          # Stop if the parse failed...
          line1 = "Parsing failed\n"
          line2 = "Reason: #{result.failure_reason.message}"
          raise SyntaxError, line1 + line2
        end

        return engine.convert(result) # engine.to_ptree(result)
      end
    end # class
  end # module
end # module