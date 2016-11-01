# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/token'


module GrammarL0Helper
  ########################################
  # Factory method. Define a grammar for a micro English-like language
  # based on Jurafky & Martin L0 language (chapter 12 of the book).
  # It defines the syntax of a sentence in a language with a 
  # very limited syntax and lexicon in the context of airline reservation.
  def grammar_L0_builder()
    builder = Rley::Syntax::GrammarBuilder.new
    builder.add_terminals('Noun', 'Verb', 'Pronoun', 'Proper-Noun')
    builder.add_terminals('Determiner', 'Preposition', )
    builder.add_production('S' => %w[NP VP])
    builder.add_production('NP' => 'Pronoun')
    builder.add_production('NP' => 'Proper-Noun')
    builder.add_production('NP' => %w[Determiner Nominal])
    builder.add_production('Nominal' => %w[Nominal Noun])
    builder.add_production('Nominal' => 'Noun')
    builder.add_production('VP' => 'Verb')
    builder.add_production('VP' => %w[Verb NP])
    builder.add_production('VP' => %w[Verb NP PP])
    builder.add_production('VP' => %w[Verb PP])
    builder.add_production('PP' => %w[Preposition PP])
    builder
  end
  
  # Return the language lexicon.
  # A lexicon is just a Hash with pairs of the form:
  # word => terminal symbol name
  def lexicon_L0()
    lexicon = {
      'flight' => 'Noun',
      'breeze' => 'Noun',
      'trip' => 'Noun',
      'morning' => 'Noun',
      'is' => 'Verb',
      'prefer' => 'Verb',
      'like' => 'Verb',
      'need' => 'Verb',
      'want' => 'Verb',
      'fly' => 'Verb',
      'me' => 'Pronoun',
      'I' => 'Pronoun',
      'you' => 'Pronoun',
      'it' => 'Pronoun',
      'Alaska' => 'Proper-Noun',
      'Baltimore' => 'Proper-Noun',
      'Chicago' => 'Proper-Noun',
      'United' => 'Proper-Noun',
      'American' => 'Proper-Noun',
      'the' => 'Determiner',
      'a' => 'Determiner',
      'an' => 'Determiner',
      'this' => 'Determiner',
      'these' => 'Determiner',
      'that' => 'Determiner',
      'from' => 'Preposition',
      'to' => 'Preposition',
      'on' => 'Preposition',
      'near' => 'Preposition'
    }
  end
  
  
  # Highly simplified tokenizer implementation.
  def tokenizer_L0(aText, aGrammar)
    tokens = aText.scan(/\S+/).map do |word|
      term_name = lexicon_L0[word]
      if term_name.nil?
        fail StandardError, "Word '#{word}' not found in lexicon"
      end
      terminal = aGrammar.name2symbol[term_name]
      Rley::Parser::Token.new(word, terminal)
    end
    
    return tokens
  end
end # module