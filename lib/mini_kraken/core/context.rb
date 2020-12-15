# frozen_string_literal: true

require 'securerandom'
require 'set'

require_relative 'any_value'
require_relative 'association'
require_relative 'blackboard'
require_relative 'fusion'
require_relative 'log_var'
require_relative 'symbol_table'
require_relative '../composite/all_composite'

module MiniKraken
  module Core
    # The data structure that provides the information required at runtime
    # to determine a MiniKraken computation. One can think of the context
    # object as a container of the symbol table and the blackboard.
    # The symbol table keeps tracks of the different scopes involved in
    # when MiniKraken is executing and the blackboard keeps the progress
    # towards the achievement (or not) of the provided goals.
    class Context
      # An inverse mapping from a combining variable i_name to the fused
      # variables i_name
      # @return [Hash{String => Array<String>}]
      attr_reader :cv2vars

      # @return [Core::SymbolTable] The MiniKraken symbol table
      attr_reader :symbol_table

      # @return [Core::Blackboard] Holds variable bindings and backtrack points.
      attr_reader :blackboard

      # Variables that remain unbound in a solution, are given a rank number.
      # This rank number is used when variable values must be displayed.
      # Since an unbound variable can take any value, the special notation
      # '_' + rank number is used to represent this state .
      # The Reasoned Schemer book calls these variable as "reified".
      # @return [Hash{String => Integer}]
      attr_reader :ranking

      # Initialize the context to a blank structure
      def initialize
        @vars2cv = {}
        @cv2vars = {}
        @symbol_table = SymbolTable.new
        @blackboard = Blackboard.new
        clear_ranking
      end

      # Notification that the current goal failed.
      # @return [Core::Context] self
      def failed!
        blackboard.failed!
        self
      end

      # Notification that the current goal succeeded.
      # @return [Core::Context] self
      def succeeded!
        blackboard.succeeded!
        self
      end

      # Does the latest result in the context represent a failure?
      # @return [Boolean] true if failure, false otherwise
      def failure?
        blackboard.failure?
      end

      # Does the latest result in the context represent success?
      # @return [Boolean] true if success, false otherwise
      def success?
        blackboard.success?
      end

      # Add an entry in the symbol table
      # @param anEntry [Core::LogVar]
      # @return [String] Internal name of the entry
      def insert(anEntry)
        symbol_table.insert(anEntry)
      end

      # Add one or more logical variable to the current scope
      # @param var_names [String, Array<String>] one or more variable names
      def add_vars(var_names)
        vnames = var_names.kind_of?(String) ? [var_names] : var_names
        vnames.each { |nm| insert(LogVar.new(nm)) }
      end

      # Search for the object with the given name
      # @param aName [String]
      # @return [Core::LogVar]
      def lookup(aName)
         symbol_table.lookup(aName)
      end

      # Set the provided scope as the current one
      # @param aScope [Core::Scope]
      def enter_scope(aScope)
        # puts __callee__
        symbol_table.enter_scope(aScope)
        blackboard.enter_scope
      end

      # Pop the current scope and make its parent the current one
      def leave_scope
        # puts __callee__
        current_scope = symbol_table.current_scope
        parent_scope = current_scope.parent
        return unless parent_scope

        # Retrieve all i_names from current scope
        i_name_set = Set.new(current_scope.defns.values.map(&:i_name))

        # Remove all associations from queue until the scope's bookmark
        items = blackboard.leave_scope
        curr_asc, ancestor_asc = items.partition do |a|
          i_name_set.include? a.i_name
        end
        vars_to_keep = Set.new

        ancestor_asc.each do |assoc|
          if assoc.dependencies(self).intersect?(i_name_set)
            dependents = assoc.dependencies(self).intersection(i_name_set)
            vars_to_keep.merge(dependents)
          end
          enqueue_association(assoc, nil) # parent_scope
        end

        assocs_to_keep = []

        unless vars_to_keep.empty?
          loop do
            to_keep, to_consider = curr_asc.partition do |a|
              vars_to_keep.include? a.i_name
            end
            break if to_keep.empty?

            to_keep.each do |a|
              vars_to_keep.merge(a.dependencies(self).intersection(i_name_set))
            end
            assocs_to_keep.concat(to_keep)
            curr_asc = to_consider
          end
        end
        symbol_table.leave_scope

        vars_to_keep.each do |i_name|
          v = LogVar.new(i_name)
          v.suffix = ''
          symbol_table.insert(v)
        end

        assocs_to_keep.each { |a| blackboard.enqueue_association(a) }
      end

      # Add the given association to the association queue
      # @param anAssociation [Core::Association] something to bind to the variable
      # @param aScope [Core::Scope, NilClass]
      def enqueue_association(anAssociation, aScope = nil)
        if aScope
          raise NotImplementedError
        else
          blackboard.enqueue_association(anAssociation)
        end
      end

      # Build an assocation and enqueue it.
      # @param aName [String, #name] User-friendly name
      # @param aValue [Core::Term]
      # @param aScope [Core::Scope, NilClass]
      def associate(aName, aValue, aScope = nil)
        name = aName.kind_of?(String) ? aName : aName.name
        if aScope
          raise NotImplementedError
        else
          vr = symbol_table.lookup(name)
          as = Association.new(blackboard.relevant_i_name(vr.i_name), aValue)
          enqueue_association(as)
        end
      end

      # Retrieve the association(s) for the variable with given name
      # By default, the variable is assumed to belong to top-level scope.
      # @param aName [String] User-friendly name of the logical variable
      # @param aScope [Core::Scope, NilClass]
      # @return [Array<Core::Association>]
      def associations_for(aName, aScope = nil)
        unless aName.kind_of?(String)
          raise StandardError, "Invalid argument #{aName}"
        end
        if aScope
          raise NotImplementedError
        else
          vr = symbol_table.lookup(aName)
          blackboard.associations_for(vr.i_name, true)
        end
      end

      # Two or more variables have to be fused.
      #   - Create a new (combining) variable
      #   - Create a fusion object
      # @param names [Array<String>] Array of user-friendly names of variables to fuse.
      def fuse(names)
        return if names.size <= 1

        vars = names.map { |nm| symbol_table.lookup(nm) }
        i_names = vars.map(&:i_name)

        # Create a new combining variable
        new_name = fusion_name
        cv_i_name = insert(LogVar.new(new_name))

        # Update the mappings
        @cv2vars[cv_i_name] = i_names.dup
        i_names.each { |i_nm|  @vars2cv[i_nm]  = cv_i_name }

        # Add fusion record to blackboard
        fs = Fusion.new(cv_i_name, i_names)
        blackboard.enqueue_fusion(fs)
      end

      def place_bt_point
        # puts __callee__
        blackboard.place_bt_point
      end

      def next_alternative
        # puts __callee__
        blackboard.next_alternative
      end

      def retract_bt_point
        # puts __callee__
        blackboard.retract_bt_point
      end

      # Returns a Hash with pairs of the form:
      #   { String => Association }, or
      #   { String => AnyValue }
      def build_zolution
        clear_ranking
        calc_ranking
        solution = {}
        return solution if failure?

        # require 'debug'
        symbol_table.root.defns.each_pair do |nm, item|
          next unless item.kind_of?(LogVar)
          if failure?
            solution[nm] = nil
            next
          end
          i_name = item.i_name
          assocs = blackboard.associations_for(i_name, true)
          if assocs.nil? || assocs.empty? ||
            (blackboard.fused?(i_name) && assocs.empty?)
            solution[nm] = AnyValue.new(ranking[i_name])
          else
            my_assocs = []
            assocs.each { |a| my_assocs << a if a.kind_of?(Association) }
            next if my_assocs.empty?
            # TODO: if multiple associations, conj2 them...
            as = my_assocs.first

            deps = as.dependencies(self)
            if deps.any? { |i_name_dep| ranking.include? i_name_dep }
              # At least one dependent variable in expression is unbound
              solution[nm] = substitute(as)
            else
              solution[nm] = as.value
            end
          end
        end
        # Take into current scope (e.g. x).
        # e.g. if q depends on other inner scope variable,
        # then one should replace every occurrence of x by AnyValue

        solution
      end
=begin
  find a solution for 1:67
  Scope picture:
  s_a:
    q
  ----
  s_b:
    x
  ----
  s_c:
    y

  Move_queue
  bk(s_b)
  bk(s_c)
  assoc x => :split
  assoc y => :pea
  assoc r => '(,x ,y)

  Let solution be a Hash i_name => value expression
  Let substitutions be a Hash i_name => value expression
  Start with root variables:
    For each root variable:
      Given q:
      Is it unbound? N
      Is it fused? N
      Get its association (Assumption: one association only)
      q => '( ,x ,y)
      dependents:
        Set { x, y}
        Given x:
          Is it unbound? N
          Is it fused? N
          Get its association
          x => :split
          no dependents => pinned, not a root variable:
            Add x => :split in substitution
            substitution = { x => :split }
        Given y:
          Is it unbound? N
          Is it fused? N
          Get its association
          y => :pea
          no dependents => pinned, not a root variable:
            Add y => :pea in substitution
            substitution = { x => :split, y => :pea }
      All dependents resolved? Y
      Add q => (:split :pea) to solution
      Done with root variables?
    Return solution: q => (split :pea)

  Let solution be a Hash i_name => value expression
  Let substitutions be a Hash i_name => value expression
Method add_substitution_for(q, substitutions):
  Is it already present in substitutions, then return

  Is it unbound? N
  Is it fused? N
  Get its association (Assumption: one association only)
    Assume q => '( ,x ,y)
      with dependents: Set { x, y}
        foreach dependent variable call
          add_substitution_for(q, substitutions) # Recursive call
      no dependents => pinned
      Add association in substitution

IDEA: placeholder in term expressions
'( ,x ,y) is translated into:
  cons(placeholder_100(nil), placeholder_200(nil))
  x => [placeholder_100]
  y => [placeholder_200]

class Placeholder {
  subj = nil
  def object_id ; subj.object_id ; end
  def kind_of? ; subj.kind_of? ; end
  def to_s ; subj.to_s ; end
}

Where are placedholders created?
- In Association.new

Do we really need Placeholder?
Do LogVarRef not fill the bill?
IDEA: at a given moment, a LogVarRef is instructed to refer to a value
Difficulty: A variable can take multiple values
Thus the logVarRef may not embed the value but refer to a value indexed by solution.

=end

      def build_solution
        solution = {}
        return solution if failure?
        substitutions = {}

        # Fill in substitutions hash by starting with root variables
        symbol_table.root.defns.each_pair do |nm, item|
          next unless item.kind_of?(LogVar)
          add_substitution_for(item.i_name, substitutions)
        end
        # require 'debug'
        handle_unbound_vars(substitutions)

        # Copy the needed associations by expanding the substitutions
        symbol_table.root.defns.each_pair do |nm, item|
          next unless item.kind_of?(LogVar)
          next if item.name =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
          i_name = item.i_name
          solution[item.name] = expand_value_of(i_name, substitutions)
        end

        solution
      end

=begin
Method add_substitution_for(q, substitutions):
  Is it already present in substitutions, then return

  Is it unbound? N
  Is it fused? N
  Get its association (Assumption: one association only)
    Assume q => '( ,x ,y)
      with dependents: Set { x, y}
        foreach dependent variable call
          add_substitution_for(q, substitutions) # Recursive call
      no dependents => pinned
      Add association in substitution
=end
      # Update the provided substitutions Hash.
      # If the given variable is dependent on other variables,
      # then the substitution is updated recursively.
      # @param iName [String] internal name of a logival variable
      # @param theSubstitutions [Hash {String => Association}]
      def add_substitution_for(iName, theSubstitutions)
        return if theSubstitutions.include? iName # Work already done...

        i_name = blackboard.fused?(iName) ? blackboard.vars2cv[iName] : iName
        assocs = blackboard.associations_for(i_name, true)
        assocs.delete_if {|e| e.kind_of?(Core::Fusion) }

        if assocs.empty?
          theSubstitutions[iName] = nil # Unbound variable
          return
        end
        # TODO: cover cases of multiple associations
        a = assocs.first
        theSubstitutions[iName] = a
        a.dependencies(self).each do |i_nm|
          # Recursive call!
          add_substitution_for(i_nm, theSubstitutions)
        end
      end

      def handle_unbound_vars(theSubstitutions)
        relevant_vars = symbol_table.all_variables.select do |vr|
          i_name = vr.i_name
          included = theSubstitutions.include? i_name
          included & theSubstitutions[i_name].nil?
        end

        rank_number = 0
        relevant_vars.each do |vr|
          i_name = vr.i_name
          if blackboard.fused?(i_name)
            cv_i_name = blackboard.vars2cv[i_name]
            fused = cv2vars[cv_i_name]
            fused << cv_i_name # TODO: delete this line
            already_ranked = fused.find { |i_nm| !theSubstitutions[i_nm].nil? }
            if already_ranked
              theSubstitutions[i_name] = theSubstitutions[already_ranked]
            else
              theSubstitutions[i_name] = AnyValue.new(rank_number)
              rank_number += 1
            end
          else
            theSubstitutions[i_name] = AnyValue.new(rank_number)
            rank_number += 1
          end
        end
      end

      def expand_value_of(iName, theSubstitutions)
        replacement = theSubstitutions[iName]
        return replacement if replacement.kind_of?(AnyValue)

        return replacement.value if replacement.dependencies(self).empty?

        value_to_expand = replacement.value
        expanded = nil

        case value_to_expand
          when LogVarRef
            expanded = expand_value_of(value_to_expand.i_name, theSubstitutions)
          when Composite::ConsCell
            expanded = value_to_expand.expand(self, theSubstitutions)
        end

        expanded
      end

      private

      # Clear the current ranking
      def clear_ranking
        @ranking = {}
      end

      # Calculate the rank of fresh variable(s) from scratch.
      def calc_ranking
        ranked = Set.new # Variables to reify (and rank)
        symbol_table.root.defns.each_value do |entry|
          next unless entry.kind_of?(LogVar)

          assocs = blackboard.associations_for(entry.i_name, true)
          if assocs.nil? || assocs.empty?
            ranked << entry.i_name
          else
            assocs.each do |a|
              if a.kind_of?(Fusion)
                comb_moves = blackboard.i_name2moves[a.i_name]
                ranked << entry.i_name if comb_moves.size == 1
              else
                dependents = a.dependencies(self)
                dependents.each do |i_name|
                  dep_idx = blackboard.i_name2moves[i_name]
                  if dep_idx.nil? || dep_idx.empty?
                    ranked << i_name
                    # TODO: consider transitive closure
                  end
                end
              end
            end
          end
        end
        # Rank the variables...
        scope = symbol_table.current_scope
        sorted_entries = []
        begin
          vars_in_scope = scope.defns.values.select { |e| e.kind_of?(LogVar) }
          if vars_in_scope
            vars_in_scope.reverse_each do |e|
              sorted_entries.unshift(e) if ranked.include? e.i_name
            end
          end
          scope = scope.parent
        end until scope.nil?

        rk_number = 0
        # Ensure that fused variables have same rank number
        sorted_entries.each do |e|
          if blackboard.fused?(e.i_name)
            siblings = cv2vars[blackboard.vars2cv[e.i_name]]
            if siblings
              occurred = siblings.find do |sb|
                ranking.include? sb
              end
              if occurred
                ranking[e.i_name] = ranking[occurred]
              end
            end
          end
          unless ranking.include? e.i_name
            ranking[e.i_name] = rk_number
            rk_number += 1
          end
        end
        ranking
      end

      # Replace any unbound variable occurring in the value expression
      # of the given association by an AnyValue instance.
      # @param anAssoc [Association]
      # @return [Term]
      def substitute(anAssoc)
        val = anAssoc.value
        deps = anAssoc.dependencies(self)
        if val.kind_of?(LogVarRef)
          i_name = anAssoc.i_name
          anAssoc.instance_variable_set(:@value, AnyValue.new(ranking[i_name]))
        else
          new_value = substitute_composite(anAssoc)
          anAssoc.instance_variable_set(:@value, new_value)
        end
      end

      # Replace any unbound variable occurring in the composite expression
      # of the given association by an AnyValue instance.
      # @param anAssoc [Association]
      # @return [Term]
      def substitute_composite(anAssoc)
        # require 'debug'
        val = anAssoc.value
        deps = anAssoc.dependencies(self)
        visitor = Composite::ConsCellVisitor.df_visitor(val)
        result = curr_cell = nil
        path = []
        loop do
          side, obj = visitor.resume
          break if side == :stop

          member_val = nil
          case obj
            when Composite::ConsCell
              member_val = Composite::ConsCell.new(42) # Workaround: make non-null
              if curr_cell
                curr_cell.set!(side, member_val)
              else
                result = member_val
                member_val.set_car!(nil)
              end
              curr_cell = member_val
              path.push curr_cell
            when LogVarRef
              nm = lookup(obj.name).i_name
              rank = ranking[nm]
              member_val = rank.nil? ? obj : AnyValue.new(rank)
              curr_cell.set!(side, member_val)
            else
              member_val = obj
              curr_cell.set!(side, member_val)
          end
          if side == :cdr
            curr_cell = path.pop
          end
        end

        result
      end

      # Return the name of a variable resulting from a fusion of
      # two or more variables.
      # @return [String]
      def fusion_name
        SecureRandom.uuid
      end
    end # class
  end # module
end # module
