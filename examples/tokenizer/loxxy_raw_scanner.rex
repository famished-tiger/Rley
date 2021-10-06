# As Rubocop shouts about "offences" in the generated code, 
# we disable the detection of most of them...
# rubocop: disable Style/MutableConstant
# rubocop: disable Layout/SpaceBeforeSemicolon
# rubocop: disable Style/Alias
# rubocop: disable Style/AndOr
# rubocop: disable Style/MultilineIfModifier
# rubocop: disable Style/StringLiterals
# rubocop: disable Style/MethodDefParentheses
# rubocop: disable Security/Open
# rubocop: disable Style/TrailingCommaInArrayLiteral
# rubocop: disable Layout/EmptyLinesAroundMethodBody
# rubocop: disable Style/WhileUntilDo
# rubocop: disable Style/MultilineWhenThen
# rubocop: disable Layout/ExtraSpacing
# rubocop: disable Layout/SpaceInsideRangeLiteral
# rubocop: disable Style/CaseEquality
# rubocop: disable Style/EmptyCaseCondition
# rubocop: disable Style/SymbolArray
# rubocop: disable Lint/DuplicateBranch
# rubocop: disable Layout/EmptyLineBetweenDefs
# rubocop: disable Layout/IndentationConsistency

# The scanner for the Lox programming language to generate.
class LoxxyRawScanner
option
  lineno # Option to generate line number handling
  column # Option to generate column number handling

# Macros in `oedipus_lex` define name regexps that can be reused
# via interpolation in other macros of rule patterns
macro
  DIGIT /\d/
  ALPHA /[a-zA-Z_]/

rule
    # Rule syntax: state? regex (block|method)?
    # Delimiters, punctuators, operators
    /[ \t]+/
    /\/\/[^\r\n]*/
    /\r|\n/                        newline
    /[!=<>]=?/                     { [:SPECIAL, text] }
    /[(){},;.\-+\/*]/              { [:SPECIAL, text] }

    # Literals & identifiers
    /#{DIGIT}+(\.#{DIGIT}+)?/      { [:NUMBER, text] }
    /nil/                          { [:NIL, text] }
    /false/                        { [:FALSE, text] }
    /true/                         { [:TRUE, text] }
    /#{ALPHA}(#{ALPHA}|#{DIGIT})*/ { [:IDENTIFIER, text] }
    /""/                           { [:STRING, '""'] }
    /"/                            :IN_STRING

  :IN_STRING  /[^"]+/              { [:STRING, "\"#{text}\""] }
  :IN_STRING  /"/                  nil

inner

  # Method called in `parse` method.
  # @return [Array<Array>]
  def do_parse
    tokens = []
    while (tok = next_token) do
      (type, lexeme) = tok
      if type == :state
        self.state = lexeme
        next
      else
        tokens << [type, lexeme, lineno, column]
      end
    end

    tokens
  end

  # Increment the line number in case the \r\n? occurs.
  # Generated code works correctly with Linux end-of-line only.
  # @param txt [String]
  def newline(txt)
    if txt == '\r'
      ss.skip(/\n/) # CR LF sequence

      self.lineno += 1
      self.start_of_current_line_pos = ss.pos + 1
    end

    nil
  end
end
# rubocop: enable Style/MutableConstant
# rubocop: enable Layout/SpaceBeforeSemicolon
# rubocop: enable Style/Alias
# rubocop: enable Style/AndOr
# rubocop: enable Style/MultilineIfModifier
# rubocop: enable Style/StringLiterals
# rubocop: enable Style/MethodDefParentheses
# rubocop: enable Security/Open
# rubocop: enable Style/TrailingCommaInArrayLiteral
# rubocop: enable Layout/EmptyLinesAroundMethodBody
# rubocop: enable Style/WhileUntilDo
# rubocop: enable Style/MultilineWhenThen
# rubocop: enable Layout/ExtraSpacing
# rubocop: enable Layout/SpaceInsideRangeLiteral
# rubocop: enable Style/CaseEquality
# rubocop: enable Style/EmptyCaseCondition
# rubocop: enable Style/SymbolArray
# rubocop: enable Lint/DuplicateBranch
# rubocop: enable Layout/EmptyLineBetweenDefs
# rubocop: enable Layout/IndentationConsistency
