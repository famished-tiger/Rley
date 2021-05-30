# frozen_string_literal: true

# File: step_defs.rb
# A few step definitions for demo and testing purpose.
require_relative '../../lib/rley/parser/gfg_earley_parser'

Given(/^I define the following grammar:$/) do |raw_rules|
  tokenized_rules = parse_rules(raw_rules)
  @grammar = build_grammar(tokenized_rules)
end


Given(/^I parse the following input:$/) do |raw_lexemes|
  lexeme_seq = raw_lexemes.strip.split
  @tokens = build_token_sequence(lexeme_seq, @grammar)
  recognizer = Rley::Parser::GFGEarleyParser.new(@grammar)
  @parsing = recognizer.parse(@tokens)
end

Given(/^I want to build the parse forest$/) do
  @ctx = prepare_build
end

Then(/^I expect curr_entry_set_index to be (\d+)$/) do |expected_index|
  expect(@ctx.curr_entry_set_index).to eq(expected_index.to_i)
end

Then(/^I expect curr_entry to be '([^']+)'$/) do |label|
  entry = @ctx.curr_entry
  expect(entry.to_s).to eq(label)
end

# End of file
