# Grammar for a simple subset of English language
# It is called nano-English because it has a more elaborate
# grammar than pico-English but remains still tiny compared to "real" English
require 'rley' # Load the gem


########################################
# Define a grammar for a nano English-like language
# based on chapter 12 from Jurafski & Martin book.
# Daniel Jurafsky,‎ James H. Martin: "Speech and Language Processing";
# 2009, Pearson Education, Inc., ISBN 978-0135041963
# It defines the syntax of a sentence in a mini English-like language 
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('Pronoun', 'Proper-Noun')
  add_terminals('Determiner', 'Noun')
  add_terminals('Cardinal_number', 'Ordinal_number', 'Quant')
  add_terminals('Verb', 'GerundV', 'Aux')
  add_terminals('Predeterminer', 'Preposition')

  rule 'language' => 'sentence'
  rule 'sentence' => 'declarative'
  rule 'sentence' => 'imperative'  
  rule 'sentence' => 'yes_no_question'
  rule 'sentence' => 'wh_subject_question'
  rule 'sentence' => 'wh_non_subject_question'
  rule 'declarative' => %w[NP VP]
  rule 'imperative' => 'VP'
  rule 'yes_no_question' => %w[Aux NP VP]
  rule 'wh_subject_question' => %w[Wh_NP NP VP]
  rule 'wh_non_subject_question' => %w[Wh_NP Aux NP VP]
  rule 'NP' => %[Predeterminer NP]
  rule 'NP' => 'Pronoun'
  rule 'NP' => 'Proper-Noun'
  rule 'NP' => %w[Det Card Ord Quant Nominal] 
  rule 'VP' => 'Verb'
  rule 'VP' => %w[Verb NP]
  rule 'VP' => %w[Verb NP PP]
  rule 'VP' => %w[Verb PP]
  rule 'Det' => 'Determiner'
  rule 'Det' => []
  rule 'Card' => 'Cardinal_number'
  rule 'Card' => []
  rule 'Ord' => 'Ordinal_number'
  rule 'Ord' =>  []  
  rule 'Nominal' => 'Noun'
  rule 'Nominal' => %[Nominal Noun]
  rule 'Nominal' => %w[Nominal GerundVP]
  rule 'Nominal' => %w[Nominal RelClause]
  rule 'PP' => %w[Preposition NP]  
  rule 'GerundVP' => 'GerundV'
  rule 'GerundVP' => %w[GerundV NP]
  rule 'GerundVP' => %w[GerundV NP PP]
  rule 'GerundVP' => %w[GerundV PP]
  rule 'RelClause' => %w[Relative_pronoun VP]

end

# And now build the grammar...
NanoGrammar = builder.grammar
