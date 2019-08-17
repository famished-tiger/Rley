# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/lexical/token'


# Mixin module implementing expectation helper methods.
module ExpectationHelper
  # Helper method. Compare the data from all the parse entries
  # of a given ParseEntrySet with an array of expectation strings.
  def compare_entry_texts(anEntrySet, expectations)
    raise StandardError, 'Nil entry set' if anEntrySet.nil?

    (0...expectations.size).each do |i|
      expect(anEntrySet.entries[i].to_s).to eq(expectations[i])
    end
  end

  # Helper method. Compare the antecedents from all the parse entries
  # of a given ParseEntrySet at given position with a Hash of the form:
  # consequent label => [ antecedent label(s) ]
  def check_antecedence(aParsing, aPosition, expectations)
    entry_set = aParsing.chart[aPosition]

    expectations.each do |consequent_label, antecedent_labels|
      consequent = entry_set.entries.find do |entry|
        entry.to_s == consequent_label
      end
      actual_antecedents = aParsing.antecedence.fetch(consequent)
      expect(actual_antecedents.map(&:to_s)).to eq(antecedent_labels)
    end
  end

  def expected_terminals(anEntrySet, termNames)
    terminals = anEntrySet.expected_terminals
    actual_names = terminals.map(&:name)
    expect(actual_names.sort).to eq(termNames.sort)
  end
end # module
# End of file
