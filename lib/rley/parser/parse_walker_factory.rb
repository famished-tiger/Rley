require 'set'
require_relative '../gfg/call_edge'
require_relative '../gfg/scan_edge'
require_relative '../gfg/epsilon_edge'
require_relative '../gfg/end_vertex'
require_relative '../gfg/item_vertex'
require_relative '../gfg/start_vertex'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    ParseWalkerContext = Struct.new(
      :curr_entry, # Parse entry currently being visited
      :entry_set_index, # Sigma set index of current parse entry
      :visitees, # The set of already visited parse entries
      :nterm2start, # Nested hashes. Pairs of first level are of the form:
      # non-terminal symbol => { index(=origin) => start entry }
      :return_stack, # A stack of parse entries
      :backtrack_points
    )

    WalkerBacktrackpoint = Struct.new(
      :entry_set_index, # Sigma set index of current parse entry
      :return_stack, # A stack of parse entries
      :visitee, # The parse entry being visited
      :antecedent_index
    )


    # A factory that creates an enumerator
    #  that itself walks through a given parsing graph.
    # The walker yields visit events.
    # Terminology warning: this class implements an external iterator
    # for a given GFGParsing object. In other words, its instances are objects
    # distinct for the GFGParsing.
    # This is different from the internal iterators, usually implemented 
    # in Ruby with an :each method.
    # Allows to perform a backwards traversal over the relevant parse entries.
    # backwards traversal means that the traversal starts from the 
    # accepting (final) parse entries and goes to the initial parse entry.
    # Relevant parse entries are parse entries that "count" in the parse
    # (i.e. they belong to a path that leads to the accepting parse entry)
    class ParseWalkerFactory
      # Build an Enumerator that will yield the parse entries as it
      # walks backwards on the parse graph
      def build_walker(acceptingEntry, maxIndex)
        # Local context for the enumerator
        ctx = init_context(acceptingEntry, maxIndex)

        walker = Enumerator.new do |receiver| # 'receiver' is a Yielder
          # At this point: current entry == accepting entry

          loop do
            event = visit_entry(ctx.curr_entry, ctx)
            receiver << event unless event.nil?

            if ctx.curr_entry.orphan? # No antecedent?...
              break if ctx.backtrack_points.empty?
              receiver << use_backtrack_point(ctx)
              receiver << visit_entry(ctx.curr_entry, ctx)
            end

            result = jump_to_antecedent(ctx)
            # Emit detection of scan edge if any...
            receiver << result[0] if result.size > 1
            ctx.curr_entry = result.last
          end
        end

        return walker
      end

      private

      # Context factory method
      def init_context(acceptingEntry, maxIndex)
        context = ParseWalkerContext.new
        context.entry_set_index = maxIndex
        context.curr_entry = acceptingEntry
        context.visitees = Set.new
        context.nterm2start = init_nterm2start
        context.return_stack = []
        context.backtrack_points = []

        return context
      end
      
      
      # Initialize the non-terminal to start entry mapping
      def init_nterm2start()
        h = Hash.new do |hsh, defval|
          entry, index = defval
          nonterm = entry.vertex.non_terminal          
          if hsh.include? nonterm
            pre = hsh[nonterm]
            pre[index] = entry
          else
            hsh[nonterm] = { index => entry }
          end
        end
          
        return h
      end

      # [event, entry, index, vertex]
      def visit_entry(anEntry, aContext)
        index = aContext.entry_set_index

        aContext.nterm2start[[anEntry, index]] if anEntry.start_entry?

        if aContext.visitees.include?(anEntry) # Already visited?...
          case anEntry.vertex
            when GFG::EndVertex
              # Jump to related start entry...
              pairs = aContext.nterm2start[anEntry.vertex.non_terminal]
              new_entry = pairs[anEntry.origin]
              aContext.curr_entry = new_entry
              aContext.entry_set_index = new_entry.origin
              event = [:revisit, anEntry, index]

            when GFG::StartVertex
              event = [:revisit, anEntry, index]

            when GFG::ItemVertex
              # Skip item entries while revisiting
              event = [:revisit, anEntry, index]
            else
              raise NotImplementedError
          end
        else
          # first time visit
          aContext.visitees << anEntry
          event = [:visit, anEntry, index]
        end

        return event
      end

      def detect_scan_edge(_ctx)
        return nil unless aContext.curr_entry.dotted_entry?
      end


      # Given the current entry from context object
      # Go to the parse entry that is one of its antecedent
      # The context object is updated
      def jump_to_antecedent(aContext)
        entries = []
        return entries if aContext.curr_entry.orphan?

        entries = if aContext.curr_entry.antecedents.size == 1
                    antecedent_of(aContext)
                  else
                    select_antecedent(aContext)
                  end

        return entries
      end

      # Handle the case of an entry having one antecedent only
      def antecedent_of(aContext)
        new_entry = aContext.curr_entry.antecedents.first
        events = [new_entry]
        traversed_edge = new_entry.vertex.edges.first
        if new_entry.vertex.kind_of?(GFG::EndVertex)
          # Return edge encountered
          # Push current entry onto stack
          # puts "Push on return stack #{aContext.curr_entry}"
          aContext.return_stack << aContext.curr_entry
        elsif traversed_edge.kind_of?(GFG::CallEdge)
          # Pop top of stack
          fail ScriptError, "Return stack empty!" if aContext.return_stack.empty?
          aContext.return_stack.pop
          # puts "Pop from return stack matching entry #{new_entry}"
        elsif traversed_edge.kind_of?(GFG::ScanEdge)
          # Scan edge encountered, decrease sigma set index
          aContext.entry_set_index -= 1
        elsif traversed_edge.kind_of?(GFG::EpsilonEdge)
          # Do nothing
        else
          raise NotImplementedError, "edge is a #{traversed_edge.class}"
        end

        return events
      end

      # Handle the case of an entry having multiple antecedents
      def select_antecedent(aContext)
        case aContext.curr_entry.vertex
          when GFG::EndVertex
            # puts "Add backtrack point stack #{aContext.curr_entry}"
            bp = add_backtrack_point(aContext)
            new_entry = bp.visitee.antecedents[bp.antecedent_index]

          when GFG::StartVertex
            new_entry = select_calling_entry(aContext)
            
          when GFG::ItemVertex
            # Push current entry onto stack
            # puts "Special push on return stack #{aContext.curr_entry}"
            aContext.return_stack << aContext.curr_entry        
            # puts "Add special backtrack point stack #{aContext.curr_entry}"
            bp = add_backtrack_point(aContext)
            new_entry = bp.visitee.antecedents[bp.antecedent_index]          
          else
            raise StandardError, 'Internal error'
        end

        return [ new_entry ]
      end

      def add_backtrack_point(aContext)
        bp = WalkerBacktrackpoint.new

        bp.entry_set_index = aContext.entry_set_index
        bp.return_stack = aContext.return_stack.dup
        bp.visitee = aContext.curr_entry
        bp.antecedent_index = 0
        aContext.backtrack_points << bp

        return bp
      end


      def use_backtrack_point(aContext)
        bp = aContext.backtrack_points.last
        bp.antecedent_index += 1

        # Restore state
        aContext.entry_set_index = bp.entry_set_index
        aContext.return_stack = bp.return_stack.dup
        aContext.curr_entry = bp.visitee.antecedents[bp.antecedent_index]

        # Drop backtrack point if useless in future
        if bp.antecedent_index == bp.visitee.antecedents.size - 1
          aContext.backtrack_points.pop
        end
        # puts "Backtracking to #{bp.visitee}"

        # Emit a backtrack event
        return [:backtrack, bp.visitee, aContext.entry_set_index]
      end

      # From the antecedent of the current parse entry
      # Retrieve the one that corresponds to the parse entry on
      # top of return stack
      # Observation: calling parse entry is an parse entry linked
      # to a item vertex
      def select_calling_entry(aContext)
        fail ScriptError, "Empty return stack" if aContext.return_stack.empty?
        # Retrieve top of stack
        tos = aContext.return_stack.pop
        tos_dotted_item = tos.vertex.dotted_item

        antecedents = aContext.curr_entry.antecedents
        new_entry = antecedents.find do |antecd|
          item = antecd.vertex.dotted_item
          (antecd.origin == tos.origin) && tos_dotted_item.successor_of?(item)
        end

        new_entry = aContext.curr_entry unless new_entry

        # puts "Pop from return stack matching entry #{new_entry}"
        return new_entry
      end
    end # class
  end # module
end # module
