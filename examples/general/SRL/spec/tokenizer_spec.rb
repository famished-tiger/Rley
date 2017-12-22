require_relative 'spec_helper' # Use the RSpec framework
require_relative '../lib/grammar'
require_relative '../lib/tokenizer' # Load the class under test


module SRL
  describe Tokenizer do
    def match_expectations(aTokenizer, theExpectations)
      aTokenizer.tokens.each_with_index do |token, i|
        terminal, lexeme = theExpectations[i]
        expect(token.terminal.name).to eq(terminal)
        expect(token.lexeme).to eq(lexeme)
      end
    end
  
  
    subject { Tokenizer.new('', SRL::Grammar) }    
    
    context 'Initialization:' do

      it 'should be initialized with a text to tokenize and a grammar' do
        expect { Tokenizer.new('anything', SRL::Grammar) }.not_to raise_error
      end

      it 'should have its scanner initialized' do
        expect(subject.scanner).to be_kind_of(StringScanner)
      end
    end # context

    context 'Single token recognition:' do
      # it 'should tokenize delimiters and separators' do
        # subject.scanner.string = ','
        # token = subject.tokens.first
        # expect(token).to be_kind_of(Rley::Lexical::Token)
        # expect(token.terminal.name).to eq('COMMA')
        # expect(token.lexeme).to eq(',')
      # end
      
      it 'should tokenize keywords' do
        sample = 'between Exactly oncE optional TWICE'
        subject.scanner.string = sample
        subject.tokens.each do |tok|
          expect(tok).to be_kind_of(Rley::Lexical::Token)
          expect(tok.terminal.name).to eq(tok.lexeme.upcase)
        end
      end
      
      it 'should tokenize integer values' do
        subject.scanner.string = ' 123 '
        token = subject.tokens.first
        expect(token).to be_kind_of(Rley::Lexical::Token)
        expect(token.terminal.name).to eq('INTEGER')
        expect(token.lexeme).to eq('123')
      end 

      it 'should tokenize single digits' do
        subject.scanner.string = ' 1 '
        token = subject.tokens.first
        expect(token).to be_kind_of(Rley::Lexical::Token)
        expect(token.terminal.name).to eq('DIGIT_LIT')
        expect(token.lexeme).to eq('1')
      end       
    end # context
    
    context 'Character range tokenization:' do
      it "should recognize 'letter from ... to ...'" do
        input = 'letter a to f'
        subject.scanner.string = input
        expectations = [
          ['LETTER', 'letter'],
          ['LETTER_LIT', 'a'],
          ['TO', 'to'],
          ['LETTER_LIT', 'f']
        ]
        match_expectations(subject, expectations)
      end    
    end # context
    
    context 'Quantifier tokenization:' do
      it "should recognize 'exactly ... times'" do
        input = 'exactly 4 Times'
        subject.scanner.string = input
        expectations = [
          ['EXACTLY', 'exactly'],
          ['DIGIT_LIT', '4'],
          ['TIMES', 'Times']
        ]
        match_expectations(subject, expectations)
      end
      
      it "should recognize 'between ... and ... times'" do
        input = 'Between 2 AND 4 times'
        subject.scanner.string = input
        expectations = [
          ['BETWEEN', 'Between'],
          ['DIGIT_LIT', '2'],
          ['AND', 'AND'],
          ['DIGIT_LIT', '4'],
          ['TIMES', 'times']
        ]
        match_expectations(subject, expectations)
      end

      it "should recognize 'once or more'" do
        input = 'Once or MORE'
        subject.scanner.string = input
        expectations = [
          ['ONCE', 'Once'],
          ['OR', 'or'],
          ['MORE', 'MORE']
        ]
        match_expectations(subject, expectations)
      end

      it "should recognize 'never or more'" do
        input = 'never or more'
        subject.scanner.string = input
        expectations = [
          ['NEVER', 'never'],
          ['OR', 'or'],
          ['MORE', 'more']
        ]
        match_expectations(subject, expectations)
      end 

      it "should recognize 'at least  ... times'" do
        input = 'at least 10 times'
        subject.scanner.string = input
        expectations = [
          ['AT', 'at'],
          ['LEAST', 'least'],
          ['INTEGER', '10'],
          ['TIMES', 'times']
        ]
        match_expectations(subject, expectations)
      end      
    end # context
  end # describe
end # module