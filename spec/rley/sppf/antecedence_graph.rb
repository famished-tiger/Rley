# Mix-in module that generates a Graphviz's DOT file
# that represents the precedence graph of parse entries.
module AntecedenceGraph

  def generate_graph(aParsing, aFile)
    heading = build_heading()
    aFile.puts(heading)
    
    fill_graph(aParsing, aFile)
    
    trailing = build_trailing()
    aFile.puts(trailing)
  end
  
private

  def build_heading()
    text = <<-END_STRING
  digraph entries {
  size = "7,9.5";
  page = "8.5,11";
  ratio = fill;
  rankdir = "BT"; // Draw arrows from bottom to top
END_STRING

    return text
  end
  
  def build_trailing()
    return '}'
  end
  
  def fill_graph(aParsing, aFile)
    # Associate to each parse entry a node id
    oid2node_id = build_nodes_id(aParsing)
    aParsing.chart.sets.each_with_index do |entry_set, chart_index|
      # Create the graph nodes
      aFile.puts ''
      aFile.puts(cluster_heading(chart_index))
      
      entry_set.entries.each do |entry|
        aFile.puts %Q(    #{oid2node_id[entry]}[label="#{entry}"];)
      end
      aFile.puts '  }'  # Close cluster
      
      # Create the edges
      aFile.puts ''
      entry_set.entries.each do |entry|
        antecedents = aParsing.antecedence[entry]
        antecedents.each do |antec|
          aFile.puts "  #{oid2node_id[antec]} -> #{oid2node_id[entry]};"
        end
      end      
    end    
  end
  
  # For each parse entry, associate a graph node id
  def build_nodes_id(aParsing)
    # Create a Hash with pairs of the form: object id => node id
    oid2node_id = {} 
    
    aParsing.chart.sets.each_with_index do |entry_set, chart_index|
      entry_set.entries.each_with_index do |entry, entry_index|
        oid2node_id[entry] = "node_#{chart_index}_#{entry_index}"
      end
    end

    return oid2node_id
  end

  
  def cluster_heading(anIndex)
    text = <<-END_STRING
  subgraph cluster_chart_#{anIndex} {
    style = rounded;
    color = blue;
    fontsize = 24.0;
    labeljust = "r";    
    label="chart[#{anIndex}]";
END_STRING

  return text
  end
  
  

end # module