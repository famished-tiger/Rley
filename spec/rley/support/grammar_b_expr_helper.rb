# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module GrammarBExprHelper
  # Factory method. Creates a grammar builder for a basic arithmetic
  # expression grammar.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_expr_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('+', '*', 'integer')
      rule 'P' => 'S'
      rule 'S' => %w[S + M]
      rule 'S' => 'M'
      rule 'M' => %w[M * T]
      rule 'M' => 'T'
      rule 'T' => 'integer'
    end
    builder
  end

  # Basic expression tokenizer
  def expr_tokenizer(aText)
    scanner = StringScanner.new(aText)
    tokens = []
    
    loop do
      scanner.skip(/\s+/)
      curr_pos = scanner.pos
      lexeme = scanner.scan(/\S+/)
      break unless lexeme
      case lexeme
        when '+', '*'
          terminal = lexeme
        when /^[-+]?\d+$/
          terminal = 'integer'
        else
          msg = "Unknown input text '#{lexeme}'"
          raise StandardError, msg
      end

      pos = Rley::Lexical::Position.new(1, curr_pos + 1)
      tokens << Rley::Lexical::Token.new(lexeme, terminal, pos)      
    end    

    return tokens 
  end
end # module
# End of file
