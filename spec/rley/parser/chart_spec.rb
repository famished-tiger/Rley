require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/parse_state'
require_relative '../../../lib/rley/parser/parse_tracer'

# Load the class under test
require_relative '../../../lib/rley/parser/chart'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe Chart do
      let(:count_token) { 20 }
      let(:sample_start_symbol) { double('fake_non-terminal') }
      let(:dotted_rule) { double('fake-dotted-item') }

      let(:output) { StringIO.new('', 'w') }

      let(:token_seq) do
        literals = %w(I saw John with a dog)
        literals.map { |lexeme| Token.new(lexeme, nil) }
      end

      let(:sample_tracer) { ParseTracer.new(0, output, token_seq) }
      
      # Default instantiation rule
      subject do 
        allow(dotted_rule).to receive(:lhs).and_return(sample_start_symbol)
        Chart.new([ dotted_rule ], count_token, sample_tracer) 
      end

      context 'Initialization:' do
        it 'should be created with start dotted rule, token count, tracer' do
          allow(dotted_rule).to receive(:lhs).and_return(sample_start_symbol)
          expect { Chart.new([ dotted_rule ], count_token, sample_tracer) }
            .not_to raise_error
        end

        it 'should have a seed state in first state_set' do
          seed_state = ParseState.new(dotted_rule, 0)
          expect(subject[0].states).to eq([seed_state])

          # Shorthand syntax
          expect(subject[0].first).to eq(seed_state)
        end

        it 'should have the correct state_set count' do
          expect(subject.state_sets.size).to eq(count_token + 1)
        end

        it 'should know the start dotted rule' do
          expect(subject.start_dotted_rule).to eq(dotted_rule)
        end
        
        it 'should know the start symbol' do
          expect(subject.start_symbol).to eq(sample_start_symbol)
        end

        it 'should have at least one non-empty state set' do
          expect(subject.last_index).to eq(0)
        end

        it 'should reference a tracer' do
          expect(subject.tracer).to eq(sample_tracer)
        end
      end # context

      context 'Provided services:' do
        let(:t_a) { Syntax::Terminal.new('A') }
        let(:t_b) { Syntax::Terminal.new('B') }
        let(:t_c) { Syntax::Terminal.new('C') }
        let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }

        let(:sample_prod) do
          Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
        end

        let(:origin_val) { 3 }
        let(:dotted_rule) { DottedItem.new(sample_prod, 2) }
        let(:complete_rule) { DottedItem.new(sample_prod, 3) }
        let(:sample_parse_state) { ParseState.new(dotted_rule, origin_val) }
        let(:sample_tracer) { ParseTracer.new(1, output, token_seq) }

        # Factory method.
        def parse_state(origin, aDottedRule)
          ParseState.new(aDottedRule, origin)
        end


        it 'should trace its initialization' do
          subject[0]  # Force constructor call here
          expectation = <<-SNIPPET
['I', 'saw', 'John', 'with', 'a', 'dog']
|.  I   . saw  . John . with .  a   . dog  .|
|>      .      .      .      .      .      .| [0:0] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectation)
        end

        it 'should trace parse state pushing' do
          subject[0]  # Force constructor call here
          output.string = ''

          subject.push_state(dotted_rule, 3, 5, :prediction)
          expectation = <<-SNIPPET
|.      .      .      >      .| [3:5] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectation)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
