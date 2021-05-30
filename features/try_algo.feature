Feature: trying the parse forest generation algorithm
  as a Rley developer
  so that I have a reliable algorithm implementation
  
Background: Defining the grammar and the input
  # Grammar based on paper from Elisabeth Scott
  # "SPPF=Style Parsing From Earley Recognizers" in
  # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
  # contains a hidden left recursion and a cycle
  Given I define the following grammar:
  """
  Phi => S
  S => A T
  S => a T
  A => a
  A => B A
  B => []
  T => b b b  
  """
  And I parse the following input:
  """
  a b b b
  """
  
Scenario: Something to say
  Given I want to build the parse forest
  Then I expect curr_entry_set_index to be 4
  And I expect curr_entry to be 'Phi. | 0'
  
# =================== curr_entry_set_index == 4
  # current entry is: 'Phi. | 0' @ 4
  # Retrieve the antecedents
  # 'Phi. | 0' => ['Phi => S . | 0']

# process_entry('Phi => S . | 0', PF)
  # if it is a dotted item entry (pattern is: X => α . β):
    # if there is at least one symbol before the dot
      # if that symbol is a non-terminal:
        # create a node with the non-terminal before the dot,
          # with same right extent as curr_entry_set_index
        # add the new node as first child of current_parent
        # append the new node to the curr_path

# PF:
  # Phi[0, 4]
  # +- S[?, 4]
# curr_path: Phi[0, 4] / S(?, 4)

  