# frozen_string_literal: true

require 'rley'

# Simple right recursive grammar
# based on example in D. Grune, C. Jacobs "Parsing Techniques" book
# pp. 224 et sq.
# S =>  a S;
# S => ;
# This grammar requires a time that is quadratic in the number of
# input tokens
# Similar grammar is also considered here: https://loup-vaillant.fr/tutorials/earley-parsing/right-recursion
builder = Rley::grammar_builder do
  # Define first the terminal symbols...
  add_terminals('a')

  # ... then with syntax rules
  # First found rule is considered to be the top-level rule
  rule('S' => 'a S')
  rule('S' => [])
end

# Highly simplified tokenizer implementation.
def tokenizer(aText, aGrammar)
  index = 0
  tokens = aText.scan(/a/).map do |letter_a|
    terminal = aGrammar.name2symbol['a']
    index += 1
    pos = Rley::Lexical::Position.new(1, index)
    Rley::Lexical::Token.new(letter_a, terminal, pos)
  end

  return tokens
end

right_recursive_grammar = builder.grammar.freeze


input_to_parse = 'a' * 5

parser = Rley::Parser::GFGEarleyParser.new(right_recursive_grammar)
tokens = tokenizer(input_to_parse, right_recursive_grammar)
result = parser.parse(tokens)

# p result.chart.to_s


# If we remove the .X and X. entries, then we have exactly the same output than Loup Vaillant

=begin
State[0]
  .S | 0
  S => . a S | 0
  S => . | 0
  S. | 0
State[1]
  S => a . S | 0
  .S | 1
  S => . a S | 1
  S => . | 1
  S. | 1
  S => a S . | 0
  S. | 0
State[2]
  S => a . S | 1
  .S | 2
  S => . a S | 2
  S => . | 2
  S. | 2
  S => a S . | 1
  S. | 1
  S => a S . | 0
  S. | 0
State[3]
  S => a . S | 2
  .S | 3
  S => . a S | 3
  S => . | 3
  S. | 3
  S => a S . | 2
  S. | 2
  S => a S . | 1
  S. | 1
  S => a S . | 0
  S. | 0
State[4]
  S => a . S | 3
  .S | 4
  S => . a S | 4
  S => . | 4
  S. | 4
  S => a S . | 3
  S. | 3
  S => a S . | 2
  S. | 2
  S => a S . | 1
  S. | 1
  S => a S . | 0
  S. | 0
State[5]
  S => a . S | 4
  .S | 5
  S => . a S | 5
  S => . | 5
  S. | 5
  S => a S . | 4
  S. | 4
  S => a S . | 3
  S. | 3
  S => a S . | 2
  S. | 2
  S => a S . | 1
  S. | 1
  S => a S . | 0
  S. | 0
=end

=begin
from the right recursive grammar:
  Terminals: a
  Rules:
    S => a S
    S => []

... the following table is generated:
|               | .S | S. | (S -> .a S) |
|:-------------:|:--:|:--:|-------------|
|    .S start   |    | Ta |     Tb      |
|    S. end     |    |    |             |
|  (S -> .a S)  |    | Tc |     Td      |

Two first rows are start and end nodes
Remaining rows are for nodes with outgoing scan edge

Algorithm to build the table
start node
end node
find every scan edge

=end


def build_gfg(aGrammar)
  items_builder = Object.new.extend(Rley::Base::GrmItemsBuilder)
  items = items_builder.build_dotted_items(aGrammar)
  Rley::GFG::GrmFlowGraph.new(items)
end

graph = build_gfg(right_recursive_grammar)

=begin
Execution simulation table construction
Do a df traversal from start vertex
  current_from: .S

  Visit .S ; stack = [.S]

  Visit S => .a S ; stack = [.S, S => . a S]
    scan edge detected
      table[.S] = {(S => . a S) => [[S => . a S]]}
    current_from: (S => . a S)


  Visit S => a . S; stack = [.S, S => . a S, S => a . S]
    call edge to .S
    current_from: (S => . a S)
    prov_table[(S => . a S)] => { .S => [S => a . S] }

  Visit .S; [.S, S => . a S, S => a . S, .S]
    .S is a table heading
    prov_table[(S => . a S)] => { .S => [S => a . S, .S] }
    current_from: .S

  Visit S => . ; stack = [.S, S => . a S, S => a . S, .S, S => .]
    table[.S] = {..., S. => [[S => .]]}
    current_from: .S

  Visit S. ; stack = [.S, S => . a S, S => a . S, .S, S => ., S.]
    S. is a table heading
      table[.S] = {..., S. => [[S => ., S.]]}
    current_from: S.

  Visit S => a S .; stack = [.S, S => . a S, S => a . S, .S, S => ., S., S => a S .]
    return edge to .S detected
      table[S.] =  { S. => [[S => a S ., S.]]}

  Visit S.; stack = [.S, S => . a S, S => a . S, .S, S => ., S., S => a S ., S.]
    S. fully visited; pop it from stack

  Visit S => a S .; stack = [.S, S => . a S, S => a . S, .S, S => ., S., S => a S .]
    S => a S . fully visited; pop it from stack

  Visit S.; stack = [.S, S => . a S, S => a . S, .S, S => ., S.]
    S. fully visited; pop it from stack

  Visit  S => .; stack = [.S, S => . a S, S => a . S, .S,  S => .]
     S => . fully visited; pop it from stack

  Visit .S; stack = [.S, S => . a S, S => a . S, .S]
    .S fully visited; pop it from stack

  Visit S => a . S; stack = [.S, S => . a S, S => a . S]
    S => a . S fully visited; pop it from stack

  Visit S => . a S; stack = [.S, S => . a S]
    S => . a Sfully visited; pop it from stack

  Visit .S; stack = [.S]
    .S fully visited; pop it from stack

  Stack contains couples of the type (node, node-from)
  Stack empty; table is complete
    table[.S] = {(S => . a S) => [[S => . a S, .S], S. => [[S => ., S.]]}
    table[S.] =  { S. => [[S => a S ., S.]]}
    prov_table[(S => . a S)] = { .S => [S => a . S] }
    table[(S => . a S] = { (S => . a S) =>  [S => a . S, .S, S => . a S], S. =>[[S => a S ., S., S => ., S.]] }
=end

module GraphMixin
  def build_table
    table = { start_vertex => {} }
    end_vertex = end_vertex_for[start_vertex.non_terminal]
    table[end_vertex] = {}
    term2scan_edge = {}

    vertices.each do |vx|
      next if vx.kind_of?(Rley::GFG::NonTerminalVertex)

      edge = vx.edges[0]
      next unless edge.kind_of?(Rley::GFG::ScanEdge)

      table[edge] = {}
      terminal = edge.terminal
      term2scan_edge[terminal] = [] unless term2scan_edge.include? terminal
      term2scan_edge[terminal] << edge
    end

    table
  end

  def build_raw_table
    table = { start_vertex => {} }
    end_vertex = end_vertex_for[start_vertex.non_terminal]
    table[end_vertex] = {} # table: vertex => { to_vertex => [path to_vertex] }
    visit = [start_vertex] # visit: stack of vertex to visit
    from_indices = [0] # Array of indices. Each index refers to one visitee
    vtx2count = { start_vertex => 0 }

    loop do
      break if visit.empty?

      current_from = visit[from_indices.last]
      visitee = visit.last
      visit_count = vtx2count[visitee]
      if visit_count < visitee.edges.size
        # puts visitee.label
        vtx2count[visitee] = visit_count + 1
        edge = visitee.edges[visit_count]
        # Do processing
        if edge.kind_of?(Rley::GFG::ScanEdge) || ((visitee == start_vertex) && visit_count.positive?)
          table[visitee] = {} unless table.include? visitee
          current_row = table[current_from]
          current_row[visitee] = [] unless current_row.include? visitee
          current_row[visitee].concat(visit[from_indices.last..(visit.size - 1)])
          from_indices << (visit.size - 1)
        elsif (visitee == end_vertex) && visit_count.zero?
          current_row = table[current_from]
          current_row[visitee] = [] unless current_row.include? visitee
          current_row[visitee].concat(visit[from_indices.last..(visit.size - 1)])
          from_indices << (visit.size - 1)
        end
        successor = edge.successor
        visit << successor
        vtx2count[successor] = 0 unless vtx2count.include?(successor)
      else
        if (visitee == end_vertex) && visit_count == visitee.edges.size
          current_row = table[current_from]
          current_row[visitee] = [] unless current_row.include? visitee
          slice = visit[from_indices.last..(visit.size - 1)]
          if slice.size > 1
            current_row[visitee].concat(slice)
            from_indices << (visit.size - 1)
          end
        end
        visit.pop
        from_indices.pop if from_indices.last >= visit.size
      end
    end

    table
  end

  def build_table2
    raw_table = build_raw_table
    refined_table = {}

    # To get table right
    # for every non start or end vertex:
    # Check if there is an entry for start_vertex, if yes
    # prefix path = raw_table[curr_vertex][start_vertex]
    # remove last vertex in prefix path (it's start vertex)
    # then for each entry from raw_table[start_vertex]:
    #   create a keyval pair: key, value = prefix + original value
    end_vertex = end_vertex_for[start_vertex.non_terminal]
    raw_table.each_pair do |key, val|
      if key == start_vertex || key == end_vertex
        refined_table[key] = val.dup
        next
      end

      if val.include? start_vertex
        prefix_path = val[start_vertex]
        prefix_path.pop
        start_row = raw_table[start_vertex]
        new_row = val.dup
        new_row.delete(start_vertex)
        start_row.each_pair do |to_vertex, to_path|
          new_row[to_vertex] = prefix_path + to_path
        end
        refined_table[key] = new_row
      end
    end

    refined_table
  end

  # visit_action takes two arguments: a vertex and an edge
  # return true/false if false stop traversal
  def df_traversal(aVertex, &_visit_action)
    visit = [aVertex]
    vtx2count = { aVertex => 0 }

    loop do
      break if visit.empty?

      visitee = visit.last
      visit_count = vtx2count[visitee]
      if visit_count < visitee.edges.size
        # puts visitee.label
        vtx2count[visitee] = visit_count + 1
        edge = visitee.edges[visit_count]
        resume = block_given? ? yield(visitee, edge) : true
        if resume
          successor = edge.successor
          visit << successor
          vtx2count[successor] = 0 unless vtx2count.include?(successor)
        end
      else
        visit.pop
      end
    end
  end

  def row_to_s(aRow)
    result = +''
    aRow.each_pair do |to_vertex, to_path|
      path_text = to_path.map(&:label).join(', ')
      result << "#{to_vertex.label} => [#{path_text}]\n"
    end

    result
  end
end # module

graph.extend(GraphMixin)
# graph.df_traversal(graph.start_vertex) { |n, _edge|  puts n.label; true }
# p graph.build_table.size
raw_table = graph.build_raw_table
p raw_table[graph.start_vertex]
# (S. => .a S) => [.S, S => .a S], S. => [.S, S => ., S.]

p raw_table[raw_table.keys[1]]
# S. => [S., S=> a S., S.]

p raw_table[raw_table.keys[2]]
# .S => [S => .a S, S => a .S, .S]

# raw_table[.S] = { (S. => .a S) => [.S, S => .a S], S. => [.S, S => ., S.] }
# raw_table[.S] = { S. => [S., S=> a S., S.] }
# raw_table[S => .a S] = { .S => [S => .a S, S => a .S, .S] }

refined_table = graph.build_table2
puts '=='
puts graph.row_to_s(refined_table[graph.start_vertex])
# refined_table[start_vertex] = { (S => .a S) => [.S, S => .a S], S. => [S., S => ., S.] }
puts '=='
puts graph.row_to_s(refined_table[refined_table.keys[1]])
# refined_table[S.] = { S. => [S., S => a S., S.] }
puts '=='
puts graph.row_to_s(refined_table[refined_table.keys[2]])
# refined_table[S => .a S] = { (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S],
#                              S. => [S => .a S, S => a .S, .S, S => ., S.]  }


# |               | .S | S. | (S -> .a S) |
# |:-------------:|:--:|:--:|-------------|
# |    .S start   |    | Ta |     Tb      |
# |    S. end     |    | ?? |             |
# |  (S -> .a S)  |    | Tc |     Td      |


class TransitionTable
  attr_reader(:table)

  def initialize(aTable)
    @table = aTable
  end

  def paths_from_start(aTerminalName)
    destinations = table.values.first
    result = []
    destinations.each_pair do |to_vx, path|
      next unless Rley::GFG::ItemVertex

      result << path if to_vx.next_symbol&.name == aTerminalName
    end

    result
  end

  def paths_from(from_terminal, to_terminal)
    from_vertices = table.keys.select do |vx|
      vx.kind_of?(Rley::GFG::ItemVertex) && vx.next_symbol&.name == from_terminal
    end

    result = []
    from_vertices.each do |fr_vx|
      destinations = table[fr_vx]
      destinations.each_pair do |to_vx, path|
        next unless Rley::GFG::ItemVertex

        result << path if to_vx.next_symbol&.name == to_terminal
      end
    end

    result
  end

  def paths_to_end(from_terminal)
    from_vertices = table.keys.select do |vx|
      vx.kind_of?(Rley::GFG::ItemVertex) && vx.next_symbol&.name == from_terminal
    end

    result = []
    from_vertices.each do |fr_vx|
      destinations = table[fr_vx]
      destinations.each_pair do |to_vx, path|
        result << path if to_vx.kind_of?(Rley::GFG::EndVertex)
      end
    end

    result
  end
end # class

=begin
  Simulation of recognizer algorithm
  input: aaaaa
  Reminder:
  # refined_table[start_vertex] = { (S => .a S) => [.S, S => .a S], S. => [S., S => ., S.] }
  # refined_table[S.] = { S. => [S., S => a S., S.] }
  # refined_table[S => .a S] = { (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S],
  #                              S. => [S => .a S, S => a .S, .S, S => ., S.]  }

  Maybe one needs to transform the above table into terminal => terminal table

  Computing state 0
    What is next terminal? a
    We push P1 == (S => .a S) => [.S, S => .a S]

  Computing state 1
    What is next terminal? a
    We push P2 == (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S]

  Computing state 2
    What is next terminal? a
    We push P2 == (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S]

  Computing state 3
    What is next terminal? a
    We push P2 == (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S]

  Computing state 4
    What is next terminal? a
    We push P2 == (S => .a S) => [S => .a S, S => a .S, .S, S -> .a S]

  Computing state 5
    What is next terminal? EOS
     We push P3 == S. => [S => .a S, S => a .S, .S, S => ., S.]

  Recognizer terminates here.
=end

class Recognizer
  attr_reader(:table)

  def initialize(aTable)
    @table = TransitionTable.new(aTable)
  end

  # @param enumerator [Enumerator] Enumerator that yields Terminal symbols
  def run(enum_tokens)
    states = []
    prev_terminal = nil
    paths = nil
    enum_tokens.each_with_index do |token, index|
      terminal_name = token.terminal.name
      if index.zero?
        paths = table.paths_from_start(terminal_name)
      else
        paths = table.paths_from(prev_terminal, terminal_name)
      end
      prev_terminal = terminal_name
      raise StandardError, "Error at position #{index} with #{token.lexeme}." if paths.empty?

      states << paths
    end

    paths = table.paths_to_end(prev_terminal)
    raise StandardError, "Error at position #{index} with #{token.lexeme}." if paths.empty?

    states << paths

    states
  end
end # class


recog = Recognizer.new(refined_table)
states = recog.run(tokens)
puts 'Done!'
p states[5]
# states[0] = [[.S, S => .a S]]
# states[1] = [[S => .a S, S => a .S, .S, S => .a S]]
# states[4] = [[S => .a S, S => a .S, .S, S => .a S]]
# states[5] = [[S => .a S, S => a .S, .S, S => a S., S.]]

# Simulation for second recognizer pass
# Every entry edge has an identifier
# Corresponding exit edge has same identifier negated
# Call and return edges are ambiguous when a non-terminal is lhs of multiple productions
# Creating statechart[0]:
# for each path do
#   for each item vertex do
#     push on current statechart rank, the item vertices
#  statechart[0] # next token is 'a'.  There is only one path from .S to S => .a S
#    push S => .a S @ 0
#    stack:
#      S => .a S @ 0

#  statechart[1] # next to token is 'a'. There is only one path from S => a .S to S => .a S
#    Remove vertex from previous state
#    push S => a . S @ 0
#    push S => .a S @ 1 # Start vertex discarded
#    stack:
#      S => .a S @ 1
#      S => .a S @ 0
#
#  statechart[2] # next to token is 'a'. There is only one path from S => a .S to S => .a S
#    Remove vertex from previous state
#    push S => a . S @ 1
#    push S => .a S @ 2 # Start vertex discarded
#    stack:
#      S => .a S @ 2
#      S => .a S @ 1
#      S => .a S @ 0
#
#  statechart[3] # next to token is 'a'. There is only one path from S => a .S to S => .a S
#    Remove vertex from previous state
#    push S => a . S @ 2
#    push S => .a S @ 3 # Start vertex discarded
#    stack:
#      S => .a S @ 3
#      S => .a S @ 2
#      S => .a S @ 1
#      S => .a S @ 0
#
#  statechart[4] # next to token is 'a'. There is only one path from S => a .S to S => .a S
#    Remove vertex from previous state
#    push S => a . S @ 3
#    push S => .a S @ 4 # Start vertex discarded
#    stack:
#      S => .a S @ 4
#      S => .a S @ 3
#      S => .a S @ 2
#      S => .a S @ 1
#      S => .a S @ 0
#
#  statechart[5] # next to token is EOS. There is only one path from S => a .S to S.
#    Remove vertex from previous state
#    push S => a . S @ 4
#    push .S  @ 5 ?
#    push S => . @5
#    push S. possibly add 0..n events S => a S. @ xx
#    stack:
#      S => .a S @ 4 expecting S => a S @ 4 event
#      S => .a S @ 3
#      S => .a S @ 2
#      S => .a S @ 1
#      S => .a S @ 0
#
