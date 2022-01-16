# frozen_string_literal: true

require 'rley/parse_rep/ast_base_builder'
require 'rley/engine'
require_relative 'all_ast_nodes'

# The purpose of a TOMLASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
class TOMLASTBuilder < Rley::ParseRep::ASTBaseBuilder
  unless defined?(Name2special)
    # Mapping Token name => operator | separator | delimiter characters
    # @return [Hash{String => String}]
    Name2special = {
      'COMMA' =>  ',',
      'DOT' => '.',
      'EQUAL' => '=',
      'LBRACKET' =>  '[',
      'RBRACKET' => ']',
      'LACCOLADE' => '{',
      'RACCOLADE' => '}'
    }.freeze
  end

  protected

  def terminal2node
    Terminal2NodeClass
  end

  # Method override
  def new_leaf_node(_production, _terminal, aTokenPosition, aToken)
    Rley::PTree::TerminalNode.new(aToken, aTokenPosition)
  end

  # Factory method for creating a parent node object.
  # @param aProduction [Production] Production rule
  # @param aRange [Range] Range of tokens matched by the rule
  # @param theTokens [Array] The input tokens
  # @param theChildren [Array] Children nodes (one per rhs symbol)
  def new_parent_node(aProduction, aRange, theTokens, theChildren)
    mth_name = method_name(aProduction.name)
    if respond_to?(mth_name, true)
      node = send(mth_name, aProduction, aRange, theTokens, theChildren)
    else
      # Default action...
      node = case aProduction.rhs.size
             when 0
               return_epsilon(aRange, theTokens, theChildren)
             when 1
               return_first_child(aRange, theTokens, theChildren)
             else
               node = Rley::PTree::NonTerminalNode.new(aProduction.lhs, aRange)
               theChildren&.reverse_each do |child|
                 node.add_subnode(child) if child
               end

               node
             end
    end

    node
  end

  #####################################
  #  TOML SEMANTIC ACTIONS
  #####################################

  # rule('toml' => 'expression*')
  def reduce_toml(_production, _range, _tokens, theChildren)
    @top_table = TOMLTableNode.new([])
    curr_table = @top_table # context for inserting pairs with simple keys
    theChildren[0]&.each do |pair|
      if pair.key.kind_of?(TOMLDottedKeyNode)
        elems = pair.key.subnodes[0..-2]
        is_val_table = pair.val.kind_of?(TOMLTableNode)
        # paths of dotted keys for tables start from top, otherwise from curreent table
        wk_table = is_val_table ? @top_table : curr_table
        elems.each do |path_node|
          found = wk_table[path_node.value]
          unless found
            found = TOMLTableNode.new([])
            wk_table.add_keyval(TOMLKeyvalNode.new([path_node, found]))
          end
          wk_table = found
        end

        pair_value = is_val_table ? pair.val : pair.val.value
        new_pair = TOMLKeyvalNode.new([pair.key.subnodes.last, pair_value])
        wk_table.add_keyval(new_pair)
        curr_table = pair.val if is_val_table
      elsif pair.val.kind_of?(TOMLTableNode)
          # [table]
          @top_table.add_keyval(pair)
          curr_table = pair.val
      else
        # simple key = literal
        curr_table.add_keyval(pair)
      end
    end

    @top_table
  end

  # rule('expression' => 'table')
  def reduce_table_expr(_production, _range, _tokens, theChildren)
    new_table = TOMLTableNode.new([])
    TOMLKeyvalNode.new([theChildren[0], new_table])
  end

  # rule('keyval' => 'key EQUAL val')
  def reduce_keyval(_production, _range, _tokens, theChildren)
    TOMLKeyvalNode.new([theChildren[0], theChildren[2]])
  end

  # rule('key' => 'dotted-key')
  def reduce_dotted_key(_production, _range, _tokens, theChildren)
    TOMLDottedKeyNode.new(theChildren[0].flatten)
  end

  # rule('dotted-key' => 'key DOT simple-key').tag 'dkey_items'
  def reduce_dkey_items(_production, _range, _tokens, theChildren)
    [theChildren[0], theChildren[2]]
  end

  # rule('val' => 'STRING')
  # rule('val' => 'BOOLEAN')
  # rule('val' => 'FLOAT')
  # rule('val' => 'INTEGER')
  def reduce_atomic_literal(_production, _range, _tokens, theChildren)
    TOMLLiteralNode.new(theChildren[0].token.position, theChildren[0].token.value)
  end

  # rule('array' => 'LBRACKET array-values RBRACKET').tag 'array'
  # rule('array' => 'LBRACKET array-values COMMA RBRACKET').tag 'array'
  def reduce_array(_production, _range, _tokens, theChildren)
    TOMLArrayNode.new(theChildren[1])
  end

  # rule('array-values' => 'array-values COMMA val')
  def reduce_more_array_values(_production, _range, _tokens, theChildren)
    theChildren[0] << theChildren[2]
  end

  # rule('array-values' => 'val')
  def reduce_one_array_value(_production, _range, _tokens, theChildren)
    [theChildren[0]]
  end

  # rule('std-table' => 'LBRACKET key RBRACKET')
  def reduce_std_table(_production, _range, _tokens, theChildren)
    theChildren[1]
  end

  # rule('inline-table' => 'LACCOLADE inline-table-keyvals RACCOLADE')
  def reduce_inline_table(_production, _range, _tokens, theChildren)
    TOMLiTableNode.new(theChildren[1])
  end

  # rule('inline-table-keyvals' => 'inline-table-keyvals COMMA keyval')
  def reduce_more_keyval(_production, _range, _tokens, theChildren)
    theChildren[0] << theChildren[2]
  end

  # rule('inline-table-keyvals' => 'keyval')
  def reduce_one_keyval(_production, _range, _tokens, theChildren)
    [theChildren[0]]
  end
end # class
