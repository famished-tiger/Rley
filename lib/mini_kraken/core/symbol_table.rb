# frozen_string_literal: true

require_relative 'scope'

module MiniKraken
  module Core
    # A symbol table is basically a mapping from a name onto an object
    # that holds information associated with that name. It is a data structure
    # that keeps track of variables and their respective scope where they are
    # declared. The key requirements for the symbol are:
    # - To perform fast lookup operations: given a name, retrieve the corresponding
    #   object.
    # - To allow the efficient insertion of names and related information
    # - To support the nesting of scopes
    # - To handle the entry scope and exit scope events,
    # - To cope with variable redefinition in nested scope
    # The terminology 'symbol table' comes from the compiler design
    # community.
    class SymbolTable
      # Mapping between a name and the scope(s) where it is defined
      # @return [Hash{String => Array<Scope>}]
      attr_reader :name2scopes

      # @return [Scope] The top-level scope (= root of the tree of scopes)
      attr_reader :root

      # @return [Scope] The current scope.
      attr_reader :current_scope

      # Build symbol table with given scope as root.
      # @param aScope [Core::Scope,NilClass] The top-level Scope
      def initialize(aScope = nil)
        @name2scopes = {}
        set_root(aScope) # Set default (global) scope
      end

      # Returns iff there is no entry in the symbol table
      # @return [Boolean]
      def empty?
        name2scopes.empty?
      end

      # Use this method to signal the interpreter that a given scope
      # to be a child of current scope and to be itself the new current scope.
      # @param aScope [Core::Scope] the Scope that
      def enter_scope(aScope)
        aScope.parent = current_scope
        @current_scope = aScope
      end

      def leave_scope
        # TODO: take dependencies between scopes into account

        current_scope.defns.each_pair do |nm, _item|
          scopes = name2scopes[nm]
          if scopes.size == 1
            name2scopes.delete(nm)
          else
            scopes.pop
            name2scopes[nm] = scopes
          end
        end
        raise StandardError, 'Cannot remove root scope.' if current_scope == root
        @current_scope = current_scope.parent
      end

      # Add an entry with given name to current scope.
      # @param anEntry [LogVar]
      # @return [String] Internal name of the entry
      def insert(anEntry)
        current_scope.insert(anEntry)
        name = anEntry.name
        if name2scopes.include?(name)
          name2scopes[name] << current_scope
        else
          name2scopes[name] = [current_scope]
        end

        anEntry.i_name
      end

      # Search for the object with the given name
      # @param aName [String]
      # @return [Core::LogVar]
      def lookup(aName)
        scopes = name2scopes.fetch(aName, nil)
        return nil if scopes.nil?

        sc = scopes.last
        sc.defns[aName]
      end
      
      # Search for the object with the given i_name
      # @param anIName [String]
      # @return [Core::LogVar]
      def lookup_i_name(anIName)
        found = nil
        scope = current_scope
        
        begin
          found = scope.defns.values.find { |e| e.i_name == anIName }
          break if found
          scope = scope.parent
        end while scope
        
        found
      end

      # Return all variables defined in the current .. root chain.
      # Variables are sorted top-down and left-to-right.
      def all_variables
        vars = []
        skope = current_scope
        while skope do
          vars_of_scope = skope.defns.select { |_, item| item.kind_of?(LogVar) }
          vars = vars_of_scope.values.concat(vars)
          skope = skope.parent
        end
        
        vars
      end

      private

      def set_root(aScope)
        @root = valid_scope(aScope)
        @current_scope = @root
      end

      def valid_scope(aScope)
        aScope.nil? ? Scope.new : aScope
      end
    end # class
  end # module
end # module
