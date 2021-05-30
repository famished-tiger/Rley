# frozen_string_literal: true

require 'rley'
require 'engtagger' # Load POS (Part-Of-Speech) tagger EngTagger

# REGEX to remove XML tags from Engtagger output
GET_TAG = /<(.+?)>(.*?)<.+?>/.freeze

# Text tokenizer
# Taken directly from Engtagger, will ensure uniform indexing while parsing
def clean_text(text)
    return false unless valid_text(text)

    text = text.toutf8
    cleaned_text = text
    tokenized = []
    # Tokenize the text (splitting on punctuation as you go)
    cleaned_text.split(/\s+/).each do |line|
      tokenized += split_punct(line)
    end
    words = split_sentences(tokenized)
    return words
end

def valid_text(text)
    if !text
      # there's nothing to parse
      puts 'method call on uninitialized variable'
      return false
    elsif /\A\s*\z/ =~ text
      # text is an empty string, nothing to parse
      return false
    else
      # $text is valid
      return true
    end
end

def split_sentences(array)
  # rubocop: disable Layout/ArrayAlignment
  tokenized = array
  people = %w[jr mr ms mrs dr prof esq sr sen sens rep reps gov attys attys
              supt det mssrs rev]
  army   = %w[col gen lt cmdr adm capt sgt cpl maj brig]
  inst   = %w[dept univ assn bros ph.d]
  place  = %w[arc al ave blvd bld cl ct cres exp expy dist mt mtn ft fy fwy
              hwy hway la pde pd plz pl rd st tce]
  comp   = %w[mfg inc ltd co corp]
  state  = %w[ala ariz ark cal calif colo col conn del fed fla ga ida id ill
              ind ia kans kan ken ky la me md is mass mich minn miss mo mont
              neb nebr nev mex okla ok ore penna penn pa dak tenn tex ut vt
              va wash wis wisc wy wyo usafa alta man ont que sask yuk]
  month  = %w[jan feb mar apr may jun jul aug sep sept oct nov dec]
  misc   = %w[vs etc no esp]
  abbr = {}
  [people, army, inst, place, comp, state, month, misc].flatten.each do |i|
    abbr[i] = true
  end
  words = []
  tokenized.each_with_index do |_t, i|
    if tokenized[i + 1] &&
       tokenized[i + 1] =~ /[A-Z\W]/ && tokenized[i] =~ /\A(.+)\.\z/
      w = $1
      # Don't separate the period off words that
      # meet any of the following conditions:
      #
      # 1. It is defined in one of the lists above
      # 2. It is only one letter long: Alfred E. Sloan
      # 3. It has a repeating letter-dot: U.S.A. or J.C. Penney
      unless abbr[w.downcase] ||
             w =~ /\A[a-z]\z/i || w =~ /[a-z](?:\.[a-z])+\z/i
        words << w
        words << '.'
        next
      end
    end
    words << tokenized[i]
  end

  # If the final word ends in a period..
  if words[-1] && words[-1] =~ /\A(.*\w)\.\z/
    words[-1] = $1
    words.push '.'
  end
  words
end
# rubocop: enable Layout/ArrayAlignment

# Separate punctuation from words, where appropriate. This leaves trailing
# periods in place to be dealt with later. Called by the clean_text method.
def split_punct(text)
    # If there's no punctuation, return immediately
    return [text] if /\A\w+\z/ =~ text

    # Sanity checks
    text = text.gsub(/\W{10,}/o, ' ')

    # Put quotes into a standard format
    text = text.gsub(/`(?!`)(?=.*\w)/o, '` ') # Shift left quotes off text
    text = text.gsub(/"(?=.*\w)/o, ' `` ') # Convert left quotes to ``

    # Convert left quote to `
    text = text.gsub(/(\W|^)'(?=.*\w)/o) { $1 ? "#{$1} ` " : ' ` ' }
    text = text.gsub(/"/, " '' ") # Convert (remaining) quotes to ''

    # Separate right single quotes
    text = text.gsub(/(\w)'(?!')(?=\W|$)/o, "\\1 ' ")

    # Handle all other punctuation
    text = text.gsub(/--+/o, ' - ') # Convert and separate dashes
    text = text.gsub(/,(?!\d)/o, ' , ') # Shift comma if not following by digit
    text = text.gsub(/:/o, ' :') # Shift semicolon off
    text = text.gsub(/(\.\.\.+)/o, ' \1 ') # Shift ellipses off
    text = text.gsub(/([(\[{}\])])/o, ' \1 ') # Shift off brackets

    # Shift off other ``standard'' punctuation
    text = text.gsub(/([!?#$%;~|])/o, ' \1 ')

    # English-specific contractions
    # Separate off 'd 'm 's
    text = text.gsub(/([A-Za-z])'([dms])\b/o, "\\1 '\\2")
    text = text.gsub(/n't\b/o, " n't") # Separate off n't
    text = text.gsub(/'(ve|ll|re)\b/o, " '\\1") # Separate off 've, 'll, 're
    result = text.split
    return result
end


# Instantiate a facade object as our Rley interface
nlp_engine = Rley::Engine.new

# Now build a very simplified English grammar...
nlp_engine.build_grammar do
  # Terminals have same names as POS tags returned by Engtagger
  add_terminals('NN', 'NNP')
  add_terminals('DET', 'IN', 'VBD')

  # Here we define the productions (= grammar rules)
  rule 'S' => %w[NP VP]
  rule 'NP' => 'NNP'
  rule 'NP' => %w[DET NN]
  rule 'NP' => %w[DET NN PP]
  rule 'VP' => %w[VBD NP]
  rule 'VP' => %w[VBD NP PP]
  rule 'PP' => %w[IN NP]
end

# text = "Yo I'm not done with you"
text = 'John saw Mary with a telescope'
puts "Input text --> #{text}"

tgr = EngTagger.new

# Generate raw POS output
tagged = tgr.add_tags(text)

# Generte tokenied lexicon of input text
# Instead of creating a lexicon dictionary,
# we would simply generate one each time on the fly for the current text only.
lexicon = clean_text(text)

# Convert EngTagger POS tokens in [[word, pos], ..] format
tokens = tagged.scan(GET_TAG).map { |tag, word| [word, tag.upcase] }

def tokenizer(lexicon, tokens)
  pos = -1
  rley_tokens = []
  lexicon.each_with_index do |word, i|
    term_name = tokens[i].last
    rank = Rley::Lexical::Position.new(1, pos + 1)
    pos += word.length + 1 # Assuming one space between words.
    rley_tokens << Rley::Lexical::Token.new(word, term_name, rank)
  end
  return rley_tokens
end

# Convert input text into a sequence of rley token objects...
rley_tokens = tokenizer(lexicon, tokens)

# Let Rley grok the tokens
result = nlp_engine.parse(rley_tokens)

puts "Parsing successful? #{result.success?}" # => Parsing successful? true
puts result.failure_reason.message unless result.success?

ptree = nlp_engine.convert(result)

visitor = nlp_engine.ptree_visitor(ptree)

renderer = Rley::Formatter::Asciitree.new($stdout)

# Let's visualize the parse tree (in text format...)
puts renderer.render(visitor)
