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

class LoxxyRawScanner
option
  lineno
  column

macro
  DIGIT /\d/
  ALPHA /[a-zA-Z_]/

rule
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
