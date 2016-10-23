# Mix-in module that generates a Graphviz's DOT file
# that represents the precedence graph of parse entries.
class GFGRepresentation

  def generate_graph(aParsing, aFile)
    heading = build_heading()
    aFile.puts(heading)
    
    fill_graph(aParsing.gf_graph, aFile)
    
    trailing = build_trailing()
    aFile.puts(trailing)
  end
  
private

  def build_heading()
    text = <<-END_STRING
  digraph gfg {
  size="7,9.5";
  page="8.5,11";
  ratio = fill;
END_STRING

    return text
  end
  
  def build_trailing()
    return '}'
  end
  
  def fill_graph(aGFGraph, aFile)
    all_vertices = aGFGraph.vertices.dup
    (itemized, endpoints) = all_vertices.partition do |vertex| 
      vertex.is_a?(Rley::GFG::ItemVertex) 
    end
    
    # Group start/end nodes by non-terminal symbol
    group_endings = endpoints.group_by { |endpoint| endpoint.non_terminal }
    
    # Group item vertices by lhs non-terminal symbol
    group_items = itemized.group_by { |vertex| vertex.lhs }    
    
    aFile.puts ''
    group_endings.each_pair do |nonterm, nodes|
      text = <<-END_STRING    
  subgraph cluster_#{nonterm} {
    color = transparent;
END_STRING
      aFile.puts text
      aFile.puts '    // Define the start and end nodes'      
      nodes.each do |vertex|
        # Emit the start/end nodes
        aFile.puts %Q(    node_#{vertex.object_id}[shape=box, fontsize=18.0, label="#{vertex.label}"];)
      end
      
      # Create sub-clusters by production
      subnodes = group_items[nonterm]
      subclusters = subnodes.group_by { |vertex| vertex.dotted_item.production }
      subclusters.each_pair do |prod, vertices|
        aFile.puts ''
        aFile.puts cluster_heading(prod)
        vertices.each do |vertex|
          aFile.puts %Q(      node_#{vertex.object_id}[label="#{vertex.label}"];)
        end
        aFile.puts cluster_trailing(prod)
      end      
      aFile.puts '  }'
    end

    aFile.puts ''
    aFile.puts '  // Draw the edges'
    aGFGraph.vertices.each do |from_vertex|
      from_vertex.edges.each do |anEdge|
        if from_vertex.is_a?(Rley::GFG::EndVertex)
          to_dotted_item = anEdge.successor.dotted_item
          label = "RET_#{to_dotted_item.production.object_id}_#{to_dotted_item.prev_position}"
          aFile.puts "  node_#{from_vertex.object_id}->node_#{anEdge.successor.object_id}[color=red, style=dashed, arrowhead=onormal,label=#{label}];"
        else
          if anEdge.is_a?(Rley::GFG::ScanEdge)
            aFile.puts %Q(  node_#{from_vertex.object_id}->node_#{anEdge.successor.object_id}[fontsize=18.0, label="#{anEdge.terminal}"];)
          else
            if anEdge.successor.is_a?(Rley::GFG::StartVertex)
              from_dotted_item = from_vertex.dotted_item
              label = "CALL_#{from_dotted_item.production.object_id}_#{from_dotted_item.position}" 
              aFile.puts "  node_#{from_vertex.object_id}->node_#{anEdge.successor.object_id}[color=green, label=#{label}];"              
            else
              aFile.puts "  node_#{from_vertex.object_id}->node_#{anEdge.successor.object_id};"
            end
          end
        end
      end  
    end    
  end


  def cluster_heading(anObject)
    text = <<-END_STRING
    subgraph cluster_#{anObject.object_id} {
      style = rounded;
      color = blue;
END_STRING

  return text
  end
  
  def cluster_trailing(anObject) 
   return '    }'
  end

end # module