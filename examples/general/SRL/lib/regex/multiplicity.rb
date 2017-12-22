# File: Multiplicity.rb

module SRL
  module Regex # This module is used as a namespace
    # The multiplicity specifies by how much a given expression can be repeated.
    class Multiplicity
      # The lowest acceptable repetition count
      attr_reader(:lower_bound)
      
      # The highest possible repetition count
      attr_reader(:upper_bound)

      # An indicator that specifies how to repeat (:greedy, :lazy, :possessive)
      attr_reader(:policy)
      
      # @param aLowerBound [Integer]
      # @param anUpperBound [Integer, Symbol] integer or :more symbol
      # @param aPolicy [Symbol] One of: (:greedy, :lazy, :possessive)
      def initialize(aLowerBound, anUpperBound, aPolicy)
        @lower_bound = valid_lower_bound(aLowerBound)
        @upper_bound = valid_upper_bound(anUpperBound)
        @policy = valid_policy(aPolicy)
      end
      
    public
      # Purpose: Return the String representation of the multiplicity.
      def to_str()
        case upper_bound
          when :more
            case lower_bound
              when 0
                subresult = '*'
              when 1
                subresult = '+'
              else
                subresult = "{#{lower_bound},}"
            end
            
          when lower_bound
            subresult = "{#{lower_bound}}"
          else
            if [lower_bound, upper_bound] == [0, 1]
              subresult = '?'
            else
              subresult = "{#{lower_bound},#{upper_bound}}"
            end
        end
        
        suffix = case policy
          when :greedy
            ''
          when :lazy
            '?'
          when :possessive
            '+'
        end
        
        return subresult + suffix
      end
      
      
    private
      # Validation method. Return the validated lower bound value
      def valid_lower_bound(aLowerBound)
        err_msg = "Invalid lower bound of repetition count #{aLowerBound}"
        raise StandardError, err_msg unless aLowerBound.kind_of?(Integer) 
        return aLowerBound
      end
      
      # Validation method. Return the validated lower bound value
      def valid_upper_bound(anUpperBound)
        err_msg = "Invalid upper bound of repetition count #{anUpperBound}"
        unless anUpperBound.kind_of?(Integer) || (anUpperBound == :more)	
          raise StandardError, err_msg
        end
        
        return anUpperBound
      end	
      
      # Validation method. Return the validated policy value.
      def valid_policy(aPolicy)
        err_msg = "Invalid repetition policy '#{aPolicy}'."
        valid_policies = [:greedy, :lazy, :possessive]
        raise StandardError, err_msg unless valid_policies.include? aPolicy

        return aPolicy
      end

    end # class

  end # module
end # module

# End of file