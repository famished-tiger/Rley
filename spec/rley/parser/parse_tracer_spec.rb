require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/parse_state'
require_relative '../../../lib/rley/parser/token'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_tracer'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe ParseTracer do
      let(:output) { StringIO.new('', 'w') }

      let(:token_seq) do
        literals = ['I', 'saw', 'John', 'with', 'a', 'dog']
        literals.map {|lexeme| Token.new(lexeme, nil)}
      end
      
      subject { ParseTracer.new(1, output, token_seq) } 

      context 'Creation & initialization:' do
        it 'should accept trace level 0' do
          expect { ParseTracer.new(0, output, token_seq) }.not_to raise_error
          expect(output.string).to eq('')
        end
        
# |.  I   . saw  . John . with .  a   . dog  .|
        
        it 'should accept trace level 1' do
          expect { ParseTracer.new(1, output, token_seq) }.not_to raise_error
          expectations = <<-SNIPPET
['I', 'saw', 'John', 'with', 'a', 'dog']
|.  I   . saw  . John . with .  a   . dog  .|
SNIPPET
          expect(output.string).to eq(expectations)
        end
        
        it 'should accept trace level 2' do
          expect { ParseTracer.new(2, output, token_seq) }.not_to raise_error
          expectations = <<-SNIPPET
['I', 'saw', 'John', 'with', 'a', 'dog']
|.  I   . saw  . John . with .  a   . dog  .|
SNIPPET
          expect(output.string).to eq(expectations)
        end
        
        it 'should know the trace level' do
          expect(subject.level).to eq(1)
        end
        
        it 'should know the output stream' do
          expect(subject.ostream).to eq(output)
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
        
        # Factory method.
        def parse_state(origin, aDottedRule)
          ParseState.new(aDottedRule, origin)
        end

        it 'should render a scanning step' do
          # Case: token at the beginning
          subject.ostream.string = ''
          subject.trace_scanning(1, parse_state(0, dotted_rule))
          expectations = <<-SNIPPET
|[------]      .      .      .      .      .| [0:1] sentence => A B . C
SNIPPET

          # Case: token in the middle
          subject.ostream.string = ''
          subject.trace_scanning(4, sample_parse_state)
          expectations = <<-SNIPPET
|.      .      .      [------]      .      .| [3:4] sentence => A B . C
SNIPPET
          
          # Case: token at the end
          subject.ostream.string = ''
          subject.trace_scanning(6, parse_state(5, dotted_rule))
          expectations = <<-SNIPPET
|.      .      .      .      .      [------]| [5:6] sentence => A B . C
SNIPPET
        end


        it 'should render a prediction step' do
          # Case: initial stateset
          subject.ostream.string = ''
          subject.trace_prediction(0, parse_state(0, dotted_rule))
          expectations = <<-SNIPPET
|>      .      .      .      .      .      .| [0:0] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)  
          
          # Case: stateset in the middle
          subject.ostream.string = ''
          subject.trace_prediction(3, sample_parse_state)
          expectations = <<-SNIPPET
|.      .      .      >      .      .      .| [3:3] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: final stateset
          subject.ostream.string = ''
          subject.trace_prediction(6, parse_state(6, dotted_rule))
          expectations = <<-SNIPPET
|.      .      .      .      .      .      >| [6:6] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)
        end

        it 'should render a completion step' do
          # Case: full parse completed
          subject.ostream.string = ''
          subject.trace_completion(6, parse_state(0, complete_rule))
          expectations = <<-SNIPPET
|[=========================================]| [0:6] sentence => A B C .
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the start (complete)
          subject.ostream.string = ''
          subject.trace_completion(1, parse_state(0, complete_rule))
          expectations = <<-SNIPPET
|[------]      .      .      .      .      .| [0:1] sentence => A B C .
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the start (not complete)
          subject.ostream.string = ''
          subject.trace_completion(1, parse_state(0, dotted_rule))
          expectations = <<-SNIPPET
|[------>      .      .      .      .      .| [0:1] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the middle (complete)
          subject.ostream.string = ''
          subject.trace_completion(4, parse_state(2, complete_rule))
          expectations = <<-SNIPPET
|.      .      [-------------]      .      .| [2:4] sentence => A B C .
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the middle (not complete)
          subject.ostream.string = ''
          subject.trace_completion(4, parse_state(2, dotted_rule))
          expectations = <<-SNIPPET
|.      .      [------------->      .      .| [2:4] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the end (complete)
          subject.ostream.string = ''
          subject.trace_completion(6, parse_state(3, complete_rule))
          expectations = <<-SNIPPET
|.      .      .      [--------------------]| [3:6] sentence => A B C .
SNIPPET
          expect(output.string).to eq(expectations)
          
          # Case: step at the end (not complete)
          subject.ostream.string = ''
          subject.trace_completion(6, parse_state(3, dotted_rule))
          expectations = <<-SNIPPET
|.      .      .      [-------------------->| [3:6] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectations)
        end
      end # context
    end # describe
  end # module
end # module

# End of file