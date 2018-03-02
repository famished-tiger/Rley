# File: character_spec.rb
require_relative '../spec_helper' # Use the RSpec test framework
require_relative '../../lib/regex/character'

module Regex # Open this namespace, to get rid of scope qualifiers
  describe Character do
    # This constant holds an arbitrary selection of characters
    SampleChars = [?a, ?\0, ?\u0107].freeze

    # This constant holds the codepoints of the character selection
    SampleInts = [0x61, 0, 0x0107].freeze

    # This constant holds an arbitrary selection of two characters (digrams) 
    # escape sequences
    SampleDigrams = %w[\n \e \0 \6 \k].freeze

    # This constant holds an arbitrary selection of escaped octal 
    # or hexadecimal literals
    SampleNumEscs = %w[\0 \07 \x07 \xa \x0F \u03a3 \u{a}].freeze

    before(:all) do
      # Ensure that the set of codepoints is mapping the set of chars...
      expect(SampleChars.map(&:ord)).to eq(SampleInts)
    end

    context 'Creation & initialization' do
      it 'should be created with a with an integer value (codepoint) or...' do
        SampleInts.each do |aCodepoint|
          expect { Character.new(aCodepoint) }.not_to raise_error
        end
      end

      it '...could be created with a single character String or...' do
        SampleChars.each do |aChar|
          expect { Character.new(aChar) }.not_to raise_error
        end
      end

      it '...could be created with an escape sequence' do
        # Case 1: escape sequence is a digram
        SampleDigrams.each do |anEscapeSeq|
          expect { Character.new(anEscapeSeq) }.not_to raise_error
        end

        # Case 2: escape sequence is an escaped octal or hexadecimal literal
        SampleNumEscs.each do |anEscapeSeq|
          expect { Character.new(anEscapeSeq) }.not_to raise_error
        end
      end
    end # context

    context 'Provided services' do
      it 'Should know its lexeme if created from a string' do
        # Lexeme is defined when the character was initialised from a text
        SampleChars.each do |aChar|
          ch = Character.new(aChar)
          expect(ch.lexeme).to eq(aChar)
        end
      end

      it 'Should not know its lexeme representation from a codepoint' do
        SampleInts.each do |aChar|
          ch = Character.new(aChar)
          expect(ch.lexeme).to be_nil
        end
      end

      it 'should know its String representation' do
        # Try for one character
        newOne = Character.new(?\u03a3)
        expect(newOne.char).to eq('Σ')
        expect(newOne.to_str).to eq("\u03A3")

        # Try with our chars sample
        SampleChars.each { |aChar| Character.new(aChar).to_str == aChar }

        # Try with our codepoint sample
        mapped_chars = SampleInts.map do |aCodepoint|
          Character.new(aCodepoint).char
        end
        expect(mapped_chars).to eq(SampleChars)

        # Try with our escape sequence samples
        (SampleDigrams + SampleNumEscs).each do |anEscSeq|
          expectation = String.class_eval(%Q|"#{anEscSeq}"|, __FILE__, __LINE__)
          Character.new(anEscSeq).to_str == expectation
        end
      end

      it 'should know its codepoint' do
        # Try for one character
        newOne = Character.new(?\u03a3)
        expect(newOne.codepoint).to eq(0x03a3)

        # Try with our chars sample
        allCodepoints = SampleChars.map do |aChar|
          Character.new(aChar).codepoint
        end
        expect(allCodepoints).to eq(SampleInts)

        # Try with our codepoint sample
        mapped_chars = SampleInts.each do |aCodepoint|
          expect(Character.new(aCodepoint).codepoint).to eq(aCodepoint)
        end

        # Try with our escape sequence samples
        (SampleDigrams + SampleNumEscs).each do |anEscSeq|
          expectation = String.class_eval(%Q|"#{anEscSeq}".ord()|, __FILE__, __LINE__)
          expect(Character.new(anEscSeq).codepoint).to eq(expectation)
        end
      end

      it 'should known whether it is equal to another Object' do
        newOne = Character.new(?\u03a3)

        # Case 1: test equality with itself
        expect(newOne).to eq(newOne)

        # Case 2: test equality with another Character
        expect(newOne).to eq(Character.new(?\u03a3))
        expect(newOne).not_to eq(Character.new(?\u0333))

        # Case 3: test equality with an integer value
        # (equality based on codepoint value)
        expect(newOne).to eq(0x03a3)
        expect(newOne).not_to eq(0x0333)

        # Case 4: test equality with a single-character String
        expect(newOne).to eq(?\u03a3)
        expect(newOne).not_to eq(?\u0333)

        # Case 5: test fails with multiple character strings
        expect(newOne).not_to eq('03a3')

        # Case 6: equality testing with arbitray object
        expect(newOne).not_to eq(nil)
        expect(newOne).not_to eq(Object.new)

        # In case 6, equality is based on to_s method.
        simulator = double('fake')
        expect(simulator).to receive(:to_s).and_return(?\u03a3)
        expect(newOne).to eq(simulator)

        # Create a module that re-defines the existing to_s method
        module Tweak_to_s
          def to_s() # Overwrite the existing to_s method
            return ?\u03a3
          end
        end # module
        weird = Object.new
        weird.extend(Tweak_to_s)
        expect(newOne).to eq(weird)
      end

      it 'should know its readable description' do
        ch1 = Character.new('a')
        expect(ch1.explain).to eq("the character 'a'")

        ch2 = Character.new(?\u03a3)
        expect(ch2.explain).to eq("the character '\u03a3'")
      end
    end # context
  end # describe
end # module

# End of file
