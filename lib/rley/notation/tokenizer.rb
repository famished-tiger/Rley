# frozen_string_literal: true

require 'strscan'
require_relative '../lexical/token'

module Rley
  module Notation
    # A tokenizer for the Rley notation language.
    # Responsibility: break input into a sequence of token objects.
    # The tokenizer should recognize:
    # Identifiers,
    # Number literals including single digit
    # String literals (quote delimited)
    # Delimiters: e.g. parentheses '(',  ')'
    # Separators: e.g. comma
    class Tokenizer
      # @return [StringScanner] Low-level input scanner
      attr_reader(:scanner)

      # @return [Integer] The current line number
      attr_reader(:lineno)

      # @return [Integer] Position of last start of line in the input
      attr_reader(:line_start)

      # One or two special character tokens.
      @@lexeme2name = {
        '(' => 'LEFT_PAREN',
        ')' => 'RIGHT_PAREN',
        '{' => 'LEFT_BRACE',
        '}' => 'RIGHT_BRACE',
        ',' => 'COMMA',
        '+' => 'PLUS',
        '?' => 'QUESTION_MARK',
        '*' => 'STAR',
        '..' => 'ELLIPSIS'
      }.freeze

      # Here are all the implemented Rley notation keywords
      @@keywords = %w[
        match_closest repeat
      ].map { |x| [x, x] }.to_h

      # Constructor. Initialize a tokenizer for Lox input.
      # @param source [String] Lox text to tokenize.
      def initialize(source = nil)
        @scanner = StringScanner.new('')
        start_with(source) if source
      end

      # Reset the tokenizer and make the given text, the current input.
      # @param source [String] Lox text to tokenize.
      def start_with(source)
        @scanner.string = source
        @lineno = 1
        @line_start = 0
      end

      # Scan the source and return an array of tokens.
      # @return [Array<Rley::Lexical::Token>] | Returns a sequence of tokens
      def tokens
        tok_sequence = []
        until @scanner.eos?
          token = _next_token
          tok_sequence << token unless token.nil?
        end

        return tok_sequence
      end

      private

      def _next_token
        pos_before = scanner.pos
        skip_intertoken_spaces
        ws_found = true if scanner.pos > pos_before
        curr_ch = scanner.peek(1)
        return nil if curr_ch.nil? || curr_ch.empty?

        token = nil

        if '(){},'.include? curr_ch
          # Single delimiter, separator or character
          token = build_token(@@lexeme2name[curr_ch], scanner.getch)
        elsif '?*+,'.include? curr_ch # modifier character
          # modifiers without prefix text are symbols
          symb = ws_found ? 'SYMBOL' : @@lexeme2name[curr_ch]
          token = build_token(symb, scanner.getch)
        elsif (lexeme = scanner.scan(/\.\./))
          # One or two special character tokens
          token = build_token(@@lexeme2name[lexeme], lexeme)
        elsif scanner.check(/"|'/) # Start of string detected...
          token = build_string_token
        elsif (lexeme = scanner.scan(/\d+/))
          token = build_token('INT_LIT', lexeme)
        elsif (lexeme = scanner.scan(/[a-zA-Z_][a-zA-Z_0-9]*:/))
          keyw = @@keywords[lexeme.chop!]
          token = build_token('KEY', lexeme) if keyw
          # ... error case
        elsif (lexeme = scanner.scan(/[^?*+,:(){}\s]+/))
           token = build_token('SYMBOL', lexeme)
        else # Unknown token
          col = scanner.pos - @line_start + 1
          _erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
          raise ScanError, "Error: [line #{lineno}:#{col}]: Unexpected character."
        end

        return token
      end

      def build_token(aSymbolName, aLexeme)
        begin
          lex_length = aLexeme ? aLexeme.size : 0
          col = scanner.pos - lex_length - @line_start + 1
          pos = Rley::Lexical::Position.new(@lineno, col)
          token = Rley::Lexical::Token.new(aLexeme.dup, aSymbolName, pos)
        rescue StandardError => e
          puts "Failing with '#{aSymbolName}' and '#{aLexeme}'"
          raise e
        end

        return token
      end

      # precondition: current position at leading quote
      def build_string_token
        delimiter = scanner.scan(/./)
        scan_pos = scanner.pos
        line = @lineno
        column_start = scan_pos - @line_start
        literal = +''
        loop do
          substr = scanner.scan(/[^"'\\\r\n]*/)
          if scanner.eos?
            pos_start = "line #{line}:#{column_start}"
            raise ScanError, "Error: [#{pos_start}]: Unterminated string."
          else
            literal << substr
            special = scanner.scan(/["'\\\r\n]/)
            case special
            when delimiter # Terminating quote found
              break
            when "\r"
              next_line
              special << scanner.scan(/./) if scanner.match?(/\n/)
              literal << special
            when "\n"
              next_line
              literal << special
            end
          end
        end
        pos = Rley::Lexical::Position.new(line, column_start)
        Rley::Lexical::Token.new(literal, 'STR_LIT', pos)
      end

      # Skip non-significant whitespaces and comments.
      # Advance the scanner until something significant is found.
      def skip_intertoken_spaces
        loop do
          ws_found = scanner.skip(/[ \t\f]+/) ? true : false
          nl_found = scanner.skip(/(?:\r\n)|\r|\n/)
          if nl_found
            ws_found = true
            next_line
          end

          break unless ws_found
        end

        scanner.pos
      end

      def next_line
        @lineno += 1
        @line_start = scanner.pos
      end
    end # class
  end # module
end # module
