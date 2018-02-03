# File: character.rb

require_relative 'atomic_expression'	# Access the superclass

module Regex # This module is used as a namespace

# A regular expression that matches a specific character in a given character set
class Character < AtomicExpression
	# Constant with all special 2-characters escape sequences
	DigramSequences = {
		"\\a" => 0x7, # alarm
		"\\n" => 0xA, # newline
		"\\r" => 0xD, # carriage return
		"\\t" => 0x9, # tab	
		"\\e" => 0x1B, # escape
		"\\f" => 0xC, # form feed
		"\\v" => 0xB, # vertical feed
		# Single octal digit literals
		"\\0" => 0,
		"\\1" => 1,
		"\\2" => 2,
		"\\3" => 3,
		"\\4" => 4,
		"\\5" => 5,	
		"\\6" => 6,	
		"\\7" => 7			
	}
  
  MetaChars = '\^$+?.'
	
	# The integer value that uniquely identifies the character. 
	attr_reader(:codepoint)
	
	# The initial text representation of the character (if any).
	attr_reader(:lexeme)
	
	# Constructor.
	# [aValue] Initialize the character with a either a String literal or a codepoint value.
	# Examples:
	# Initializing with codepoint value...
	# RegAn::Character.new(0x3a3)	# Represents: Σ (Unicode GREEK CAPITAL LETTER SIGMA)
	# RegAn::Character.new(931)		# Also represents: Σ (931 dec == 3a3 hex)
	#
	# Initializing with a single character string
	# RegAn::Character.new(?\u03a3) # Also represents: Σ
	# RegAn::Character.new('Σ')		# Obviously, represents a Σ
	#
	# Initializing with an escape sequence string
	# Recognized escaped characters are: \a (alarm, 0x07), \n (newline, 0xA),
	#	\r (carriage return, 0xD), \t (tab, 0x9), \e (escape, 0x1B), \f (form feed, 0xC)
	#	\uXXXX where XXXX is a 4 hex digits integer value, \u{X...}, \ooo (octal)	\xXX (hex)
	# Any other escaped character will be treated as a literal character
	# RegAn::Character.new('\n')		# Represents a newline
	# RegAn::Character.new('\u03a3')	# Represents a Σ
	def initialize(aValue)

		case aValue
			when String
				if aValue.size == 1
					# Literal single character case...
					@codepoint = self.class.char2codepoint(aValue)
				else
					# Should be an escape sequence...
					@codepoint = self.class.esc2codepoint(aValue)
				end
				@lexeme = aValue
				
			when Integer
				@codepoint = aValue
			else
				raise StandardError, "Cannot initialize a Character with a '#{aValue}'."
		end
	end
	
public
	# Convertion method that returns a character given a codepoint (integer) value.
	# Example:
	# RegAn::Character::codepoint2char(0x3a3)	# Returns: Σ (The Unicode GREEK CAPITAL LETTER SIGMA)
	def self.codepoint2char(aCodepoint)
		return [aCodepoint].pack('U')	# Remark: chr() fails with codepoints > 256
	end
	
	# Convertion method that returns the codepoint for the given single character.
	# Example:
	# RegAn::Character::char2codepoint('Σ')	# Returns: 0x3a3	
	def self.char2codepoint(aChar)
		return aChar.ord()		
	end
	
	# Convertion method that returns the codepoint for the given escape sequence (a String).
	# Recognized escaped characters are: \a (alarm, 0x07), \n (newline, 0xA),
	#	\r (carriage return, 0xD), \t (tab, 0x9), \e (escape, 0x1B), \f (form feed, 0xC), \v (vertical feed, 0xB)
	#	\uXXXX where XXXX is a 4 hex digits integer value, \u{X...}, \ooo (octal)	\xXX (hex)
	# Any other escaped character will be treated as a literal character	
	# Example:
	# RegAn::Character::esc2codepoint('\n')	# Returns: 0xd	
	def self.esc2codepoint(anEscapeSequence)
		raise StandardError, "Escape sequence #{anEscapeSequence} does not begin with a backslash (\)." unless anEscapeSequence[0] == "\\"
		result = (anEscapeSequence.length == 2)? digram2codepoint(anEscapeSequence) : esc_number2codepoint(anEscapeSequence)
		
		return result
	end
	
	# Return the character as a String object
	def char()
		self.class.codepoint2char(@codepoint)
	end
	
	# Returns true iff this Character and parameter 'another' represent the same character.
	# [another] any Object. The way the equality is tested depends on the another's class
	# Example:
	# newOne = Character.new(?\u03a3)
	# newOne == newOne	# true. Identity
	# newOne == Character.new(?\u03a3)	# true. Both have same codepoint
	# newOne == ?\u03a3	# true. The single character String match exactly the char attribute.
	# newOne == 0x03a3	# true. The Integer is compared to the codepoint value.
	# Will test equality with any Object that knows the to_s method
	def ==(another)
		result = case another
			when Character
				self.to_str == another.to_str
				
			when Integer
				self.codepoint == another
				
			when String
				(another.size > 1) ? false : self.to_str == another
				
			else
				# Unknown type: try with a convertion
				self == another.to_s()	# Recursive call
		end
		
		return result
	end
	
	# Return a plain English description of the character
	def explain()
		return "the character '#{to_str()}'"
	end
  
  protected
  
  # Conversion method re-definition.
	# Purpose: Return the String representation of the expression.
	# If the Character was initially from a text (the lexeme), then the lexeme is returned back.
	# Otherwise the character corresponding to the codepoint is returned.
	def text_repr()
		if lexeme.nil?
			result = char()
		else
			result = lexeme.dup()
		end
		
		return result
	end
	
private
	# Convertion method that returns a codepoint for the given two characters (digram) escape sequence.
	# Recognized escaped characters are: \a (alarm, 0x07), \n (newline, 0xA),
	#	\r (carriage return, 0xD), \t (tab, 0x9), \e (escape, 0x1B), \f (form feed, 0xC), \v (vertical feed, 0xB)
	# Any other escape sequence will return the codepoint of the escaped character.
	# [aDigram]	A sequence of two characters that starts with a backslash.
	def self.digram2codepoint(aDigram)
		# Check that the digram is a special escape sequence
		result = DigramSequences.fetch(aDigram, nil)
		
		# If it not a special sequence, then escaped character is considered literally (the backslash is 'dummy')
		result = char2codepoint(aDigram[-1]) if result.nil?
		return result
	end

	# Convertion method that returns a codepoint for the given complex escape sequence.	
	# [anEscapeSequence] A String with the format:
	# \uXXXX where XXXX is a 4 hex digits integer value,
	# \u{X...} X 1 or more hex digits
	# \ooo (1..3 octal digits literal)
	# \xXX (1..2 hex digits literal)
	def self.esc_number2codepoint(anEscapeSequence)
		# Next line requires Ruby >= 1.9
		unless /^\\(?:(?:(?<prefix>[uxX])\{?(?<hexa>\h+)\}?)|(?<octal>[0-7]{1,3}))$/ =~ anEscapeSequence
			raise StandardError, "Unsupported escape sequence #{anEscapeSequence}." 
		else
			#shorterSeq = anEscapeSequence[1..-1]	# Remove the backslash
		
		# Octal literal case?
			return octal.oct() if octal # shorterSeq =~ /[0-7]{1,3}/
		
			# Extract the hexadecimal number
			hexliteral = hexa # shorterSeq.sub(/^[xXu]\{?([0-9a-fA-F]+)}?$/, '\1')
			return hexliteral.hex()
		end
	end

end # class

end # module

# End of file