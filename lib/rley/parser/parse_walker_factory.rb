require 'set'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    ParseWalkerContext = Struct.new(
      :curr_entry,  # Parse entry currently being visited
      :entry_set_index,  # Sigma set index of current parse entry
      :visitees,  # The set of already visited parse entries
      :nterm2start, # A Hash non-terminal symbol => start entry
      :return_stack, # A stack of parse entries
      :backtrack_points
    )

    WalkerBacktrackpoint = Struct.new(
      :entry_set_index,  # Sigma set index of current parse entry
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
    # This is different from the internal iterators, usually implemented in Ruby
    # with an each method.
    # Allows to perform a backwards traversal over the relevant parse entries.
    # backwards traversal means that the traversal starts from the accepting (final)
    # parse entries and goes to the initial parse entry.
    # Relevant parse entries are parse entries that "count" in the parse
    # (i.e. they belong to a path that leads to the accepting parse entry)
    class ParseWalkerFactory
      # Build an Enumerator that will yield the parse entries as it
      # walks backwards on the parse graph
      def build_walker(aParseResult)
        # Local context for the enumerator
        parsing = aParseResult
        ctx = init_context(aParseResult)

        walker = Enumerator.new do |receiver| # 'receiver' is a Yielder
          # At this point: current entry == accepting entry

          loop do
            event = visit_entry(ctx.curr_entry, ctx)
            receiver << event unless event.nil?

            if ctx.curr_entry.orphan? # No antecedent?...
              if ctx.backtrack_points.empty?
                break
              else
                receiver << use_backtrack_point(ctx)
                receiver << visit_entry(ctx.curr_entry, ctx)
              end
            end

            result = jump_to_antecedent(ctx, parsing)
            # Emit detection of scan edge if any...            
            receiver << result[0] if result.size > 1
            ctx.curr_entry = result.last
          end
        end

        return walker
      end

private
      # Context factory method
      def init_context(aParseResult)
        context = ParseWalkerContext.new
        context.entry_set_index = aParseResult.chart.last_index
        context.curr_entry = aParseResult.accepting_entry
        context.visitees = Set.new
        context.nterm2start = {}
        context.return_stack = []
        context.backtrack_points = []

        return context
      end

      # [event, entry, index, vertex]
      def visit_entry(anEntry, aContext)
        index = aContext.entry_set_index

        if anEntry.start_entry?
          aContext.nterm2start[anEntry.vertex.non_terminal] = anEntry
        end

        if aContext.visitees.include?(anEntry)
          # multiple time visit
          case anEntry.vertex
            when GFG::EndVertex
              # Jump to related start entry...
              new_entry = aContext.nterm2start[anEntry.vertex.non_terminal]
              aContext.curr_entry = new_entry
              aContext.entry_set_index = new_entry.origin
              event = [:revisit, anEntry, index]

            when GFG::StartVertex
              # Skip start entries while revisiting
              event = nil

            when GFG::ItemVertex
              # Skip item entries while revisiting
              event = nil
          else
            fail NotImplementedError
          end
        else
          # first time visit
          aContext.visitees << anEntry
          event = [:visit, anEntry, index]
        end

        return event
      end

      def detect_scan_edge(ctx)
        return nil unless aContext.curr_entry.dotted_entry?
      end


      # Given the current entry from context object
      # Go to the parse entry that is one of its antecedent
      # The context object is updated
      def jump_to_antecedent(aContext, aParseResult)
        entries = []
        return entries if aContext.curr_entry.orphan?
        
        if aContext.curr_entry.antecedents.size == 1
          entries = antecedent_of(aContext, aParseResult)
        else
          entries = select_antecedent(aContext)
        end

        return entries
      end

      # Handle the case of an entry having one antecedent only
      def antecedent_of(aContext, aParseResult)
        new_entry = aContext.curr_entry.antecedents.first
        events = [new_entry]
        traversed_edge = new_entry.vertex.edges.first
        case new_entry.vertex
          when GFG::EndVertex
            # Return edge encountered
            # Push current entry onto stack
            # puts "Push on return stack #{aContext.curr_entry}"
            aContext.return_stack << aContext.curr_entry
          else
            if traversed_edge.is_a?(GFG::ScanEdge)
              # Scan edge encountered, decrease sigma set index
              aContext.entry_set_index -= 1
            end
          end

        return events
      end

      # Handle the case of an entry having multiple antecedents
      def select_antecedent(aContext)
        case aContext.curr_entry.vertex
          when GFG::EndVertex
            # puts "Add backtrack point stack #{aContext.curr_entry}"
            # An end vertex with multiple antecedents requires
            # a backtrack point for a correct graph traversal
            bp = add_backtrack_point(aContext)
            new_entry = bp.visitee.antecedents[bp.antecedent_index]

          when GFG::StartVertex
            # An start vertex with multiple requires a backtrack point
            new_entry = select_calling_entry(aContext)
          else
            fail StandardError, "Internal error"
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
        
        # Emit a backtrack event
        return [:backtrack, bp.visitee, aContext.entry_set_index]
      end

      # From the antecedent of the current parse entry
      # Retrieve the one that corresponds to the parse entry on
      # top of return stack
      # Observation: calling parse entry is an parse entry linked
      # to a item vertex
      def select_calling_entry(aContext)
        # Retrieve top of stack
        tos = aContext.return_stack.pop
        tos_dotted_item = tos.vertex.dotted_item

        antecedents = aContext.curr_entry.antecedents
        new_entry = antecedents.find do |antecd|
          item = antecd.vertex.dotted_item
          (antecd.origin == tos.origin) && tos_dotted_item.successor_of?(item)
        end
        
        # TODO: double-check validity of next line
        new_entry = aContext.curr_entry unless new_entry

        # puts "Pop from return stack matching entry #{new_entry}"
        return new_entry
      end
    end # class
  end # module
end # module