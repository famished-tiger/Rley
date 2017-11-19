require "rley"
require "engtagger"
require "pp"

# REGEX to remove XML tags from Engtagger output
GET_TAG = /<(.+?)>(.*?)<.+?>/

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
      "method call on uninitialized variable" if @conf[:debug]
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
    tokenized = array
    people = %w(jr mr ms mrs dr prof esq sr sen sens rep reps gov attys attys
                supt det mssrs rev)
    army   = %w(col gen lt cmdr adm capt sgt cpl maj brig)
    inst   = %w(dept univ assn bros ph.d)
    place  = %w(arc al ave blvd bld cl ct cres exp expy dist mt mtn ft fy fwy
                hwy hway la pde pd plz pl rd st tce)
    comp   = %w(mfg inc ltd co corp)
    state  = %w(ala ariz ark cal calif colo col conn del fed fla ga ida id ill
                ind ia kans kan ken ky la me md is mass mich minn miss mo mont
                neb nebr nev mex okla ok ore penna penn pa dak tenn tex ut vt
                va wash wis wisc wy wyo usafa alta man ont que sask yuk)
    month  = %w(jan feb mar apr may jun jul aug sep sept oct nov dec)
    misc   = %w(vs etc no esp)
    abbr = Hash.new
    [people, army, inst, place, comp, state, month, misc].flatten.each do |i|
      abbr[i] = true
    end
    words = Array.new
    tokenized.each_with_index do |t, i|
      if tokenized[i + 1] and tokenized [i + 1] =~ /[A-Z\W]/ and tokenized[i] =~ /\A(.+)\.\z/
        w = $1
        # Don't separate the period off words that
        # meet any of the following conditions:
        #
        # 1. It is defined in one of the lists above
        # 2. It is only one letter long: Alfred E. Sloan
        # 3. It has a repeating letter-dot: U.S.A. or J.C. Penney
        unless abbr[w.downcase] or w =~ /\A[a-z]\z/i or w =~ /[a-z](?:\.[a-z])+\z/i
          words <<  w
          words << '.'
          next
        end
      end
      words << tokenized[i]
    end
    # If the final word ends in a period..
    if words[-1] and words[-1] =~ /\A(.*\w)\.\z/
      words[-1] = $1
      words.push '.'
    end
    return words
end

# Separate punctuation from words, where appropriate. This leaves trailing
# periods in place to be dealt with later. Called by the clean_text method.
def split_punct(text)
    # If there's no punctuation, return immediately
    return [text] if /\A\w+\z/ =~ text
    # Sanity checks
    text = text.gsub(/\W{10,}/o, " ")

    # Put quotes into a standard format
    text = text.gsub(/`(?!`)(?=.*\w)/o, "` ") # Shift left quotes off text
    text = text.gsub(/"(?=.*\w)/o, " `` ") # Convert left quotes to ``
    text = text.gsub(/(\W|^)'(?=.*\w)/o){$1 ? $1 + " ` " : " ` "} # Convert left quotes to `
    text = text.gsub(/"/, " '' ") # Convert (remaining) quotes to ''
    text = text.gsub(/(\w)'(?!')(?=\W|$)/o){$1 + " ' "} # Separate right single quotes

    # Handle all other punctuation
    text = text.gsub(/--+/o, " - ") # Convert and separate dashes
    text = text.gsub(/,(?!\d)/o, " , ") # Shift commas off everything but numbers
    text = text.gsub(/:/o, " :") # Shift semicolons off
    text = text.gsub(/(\.\.\.+)/o){" " + $1 + " "} # Shift ellipses off
    text = text.gsub(/([\(\[\{\}\]\)])/o){" " + $1 + " "} # Shift off brackets
    text = text.gsub(/([\!\?#\$%;~|])/o){" " + $1 + " "} # Shift off other ``standard'' punctuation

    # English-specific contractions
    text = text.gsub(/([A-Za-z])'([dms])\b/o){$1 + " '" + $2}  # Separate off 'd 'm 's
    text = text.gsub(/n't\b/o, " n't")                     # Separate off n't
    text = text.gsub(/'(ve|ll|re)\b/o){" '" + $1}         # Separate off 've, 'll, 're
    result = text.split(' ')
    return result
end


# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new do

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

# And now, let's build the grammar...
grammar = builder.grammar

parser = Rley::Parser::GFGEarleyParser.new(grammar)

# text = "Yo I'm not done with you"
text= "John saw Mary with a telescope"
pp "Input text --> #{text}"

tgr = EngTagger.new

# Generte POS
tagged = tgr.add_tags(text)

# Generte tokenied lexicon of input text
# Instead of creating a lexicon dictionary, we would simply generate one each time on the fly for the current text only.
lexicon = clean_text(text)

# Generte POS tokens in [[word, pos], ..] format
tokens = tagged.scan(GET_TAG).map { |tag, word| [word, tag.upcase] }

def tokenizer(lexicon, grammar, tokens)
  rley_tokens = []
  lexicon.each_with_index do |word, i| 
    term_name = tokens[i].last
    terminal = grammar.name2symbol[term_name]
    rley_tokens << Rley::Lexical::Token.new(word, terminal)
  end
  return rley_tokens
end

# Convert input text into a sequence of rley token objects...
rley_tokens = tokenizer(lexicon, grammar, tokens)

result = parser.parse(rley_tokens)

pp "Parsing successful? #{result.success?}" # => Parsing successful? true
pp result.failure_reason.message unless result.success?

ptree = result.parse_tree

visitor = Rley::ParseTreeVisitor.new(ptree)

renderer = Rley::Formatter::Asciitree.new($stdout)

# Subscribe the formatter to the visitor's event and launch the visit
pp renderer.render(visitor)   
