# frozen_string_literal: true

require_relative '../../lib/rley/lexical/token_range'
require_relative '../../lib/rley/sppf/non_terminal_node'
require_relative '../../lib/rley/sppf/parse_forest'


module Rley4Cuke # Use the module as a namespace
  ForestBuildingContext = Struct.new(
    :curr_entry_set_index,
    :curr_entry,
    :forest,
    :curr_path,
    :curr_thread,
    :backtrack_points) do # A LIFO queue
      def current_parent
        return curr_path.last
      end

      def add_node(aNode) end
    end

  module ForestBuilder # Mixin module
    def build_parse_forest
      # Create a forest building context
      ctx = prepare_build

      fill_forest(ctx)
      ctx.forest
    end

    def prepare_build
      # Parse forest initialization
      forest = init_forest

      # Create a context object
      init_context(forest)
    end

    def fill_forest(aContext)
      # rubocop: disable Style/WhileUntilDo
      loop do # Loop over backtrack points
        antecedents = @parsing.antecedence[aContext.curr_entry]
        until antecedents.empty? do
          if antecedents.length == 1
            antecedent = antecedents.first
            process_entry(antecedent, aContext)
            aContext.current_entry = antecedent
            break # TODO: remove this
          else # multiple antecedents
            boom!
          end

          antecedents = @parsing.antecedence[aContext.curr_entry]
        end # until

        # No more antecedent, check for backtrack points
        if aContext.backtrack_points.empty?
          break # stop iterating over bp
        else
          boom!
        end
      end # loop over backtrack points
    end
    # rubocop: enable Style/WhileUntilDo

    def process_entry(anEntry, aContext) end

    private

    # Parse forest initialization
    def init_forest
      full_range = { low: 0, high: @parsing.chart.last_index }
      root_node = create_non_terminal_node(@parsing.accepting_entry, full_range)
      Rley::SPPF::ParseForest.new(root_node)
    end

    # Assumption the aParseEntry corresponds to an end GFG node
    def create_non_terminal_node(aParseEntry, aRange)
      a_vertex = aParseEntry.vertex
      Rley::SPPF::NonTerminalNode.new(a_vertex.non_terminal, aRange)
    end

    def init_context(aForest)
      ForestBuildingContext.new(@parsing.chart.last_index, # :curr_entry_set_index
        @parsing.accepting_entry, # :curr_entry
        aForest,                  # :forest
        [aForest.root],           # :curr_path
        0,                        # :curr_thread
        [])                       # :backtrack_points
    end
  end # module
end # module
# End of file
