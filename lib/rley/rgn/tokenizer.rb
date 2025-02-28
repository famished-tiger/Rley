# frozen_string_literal: true

require 'strscan'
require_relative '../lexical/token'

module Rley
  module RGN
    # A tokenizer for the Rley notation language.
    # Responsibility: break input into a sequence of token objects.
    # The tokenizer should recognize:
    # Identifiers,
    # Number literals including single digit
    # String literals (quote delimited)
    # Delimiters: e.g. parentheses '(',  ')'
    # Separators: e.g. comma
    class Tokenizer
      PATT_KEY = /[a-zA-Z_][a-zA-Z_0-9]*:/
      PATT_INTEGER = /\d+/
      PATT_NEWLINE = /(?:\r\n)|\r|\n/
      PATT_STRING_START = /"|'/
      PATT_SYMBOL = /[^?*+,:(){}\s]+/
      PATT_WHITESPACE = /[ \t\f]+/

      # @return [StringScanner] Low-level input scanner
      attr_reader(:scanner)

      # @return [Integer] The current line number
      attr_reader(:lineno)

      # @return [Integer] Position of last start of line in the input
      attr_reader(:line_start)

      # One or two special character tokens.
      Lexeme2name = {
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
      ].to_h { |x| [x, x] }

      # Constructor. Initialize a tokenizer for RGN input.
      # @param source [String] RGN text to tokenize.
      def initialize(source = nil)
        reset
        input = source || ''
        @scanner = StringScanner.new(input)
      end

      # Reset the tokenizer and make the given text, the current input.
      # @param source [String] RGN text to tokenize.
      def start_with(source)
        reset
        @scanner.string = source
      end

      # Scan the source and return an array of tokens.
      # @return [Array<Rley::Lexical::Token>] | Returns a sequence of tokens
      def tokens
        tok_sequence = []
        until @scanner.eos?
          token = _next_token
          tok_sequence << token unless token.nil?
        end

        tok_sequence
      end

      private

      def reset
        @lineno = 1
        @line_start = 0
      end

      def _next_token
        token = nil
        ws_found = false

        # Loop until end of input reached or token found
        until token || scanner.eos?

          nl_found = scanner.skip(PATT_NEWLINE)
          if nl_found
            next_line_scanned
            next
          end
          if scanner.skip(PATT_WHITESPACE) # Skip whitespaces
            ws_found = true
            next
          end

          curr_ch = scanner.peek(1)

          if '(){},'.include? curr_ch
            # Single delimiter, separator or character
            token = build_token(Lexeme2name[curr_ch], scanner.getch)
          elsif '?*+,'.include? curr_ch # modifier character
            # modifiers without prefix text are symbols
            symb = (ws_found || nl_found) ? 'SYMBOL' : Lexeme2name[curr_ch]
            token = build_token(symb, scanner.getch)
          elsif (lexeme = scanner.scan(/\.\./))
            # One or two special character tokens
            token = build_token(Lexeme2name[lexeme], lexeme)
          elsif scanner.check(PATT_STRING_START) # Start of string detected...
            token = build_string_token
          elsif (lexeme = scanner.scan(PATT_INTEGER))
            token = build_token('INT_LIT', lexeme)
          elsif (lexeme = scanner.scan(PATT_KEY))
            keyw = @@keywords[lexeme.chop!]
            token = build_token('KEY', lexeme) if keyw
            # ... error case
          elsif (lexeme = scanner.scan(PATT_SYMBOL))
             token = build_token('SYMBOL', lexeme)
          else # Unknown token
            col = scanner.pos - @line_start + 1
            _erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
            raise ScanError, "Error: [line #{lineno}:#{col}]: Unexpected character."
          end
          ws_found = false
        end # until

        token
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

      # Event: next line detected.
      def next_line_scanned
        @lineno += 1
        @line_start = scanner.pos
      end
    end # class
  end # module
end # module
