# File: MatchOption.rb

module Regex # This module is used as a namespace

# Represents an option that influences the way a regular (sub)expression can perform its matching.
class MatchOption
	# The symbolic name of the option
	attr_reader(:name)
	
	# An indicator that tells whether the option is turned on or off
	attr_reader(:setting)
	
	# Constructor.
	def initialize(theName, theSetting)
		@name, @setting = theName, theSetting
	end
	
public
	# Equality operator
	def ==(another)
		return true if self.object_id == another.object_id
		
		if another.kind_of?(MatchOption)
			isEqual = ((name == another.name) && (setting == another.setting))
		else
			isEqual = false
		end
		
		return isEqual
	end

end # class

end # module

# End of file