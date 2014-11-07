# A dotted item is a parse state for a given production/grammar rule
# It partitions the rhs of the rule in two parts. 
# The left part consists of the symbols in the rules that are matched 
# by the input tokens.
# The right part consists of symbols that are predicted to match the
# input tokens.
# The terminology stems from the traditional way to visualize the partition
# by using a fat dot character as a separator between the left and right parts
# An item with the dot at the beginning (i.e. before any rhs symbol) 
#   is called a predicted item.
# An item with the dot at the end (i.e. after all rhs symbols) 
#   is called a reduce item.
# An item with a dot in front of a terminal is called a shift item.
class DottedItem
  # Production rule 
  attr_reader(:production)
  
  # Index of the next symbol (from the rhs) after the 'dot'.
  # If the dot is at the end of the rhs (i.e.) there is no next
  # symbol, then the position takes the value -1.
  attr_reader(:position)
  
  # @param aProduction
  def initialize(aProduction, aPosition)
    @production = aProduction
    @position = valid_position(aPosition)
  end
  
  def predicted_item?()
  end
  
  def reduce_item?()
  end
  
  def shift_item?()
  end
  
  private
  
  # Return the given after its validation.
  def valid_position(aPosition)
    rhs_size = production.rhs.size
    if aPosition < 0 || aPosition > rhs_size
      fail StandardError, 'Out of bound index'
    end
    
    if rhs_size == 0
      index = -2 # Minus 2 at start/end of empty production
    elsif aPosition == rhs_size
      index = -1  # Minus 1 at end of non-empty production 
    else
      index = aPosition
    end
    
    return index
  end
end # class

# End of file
