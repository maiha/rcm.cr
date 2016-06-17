module Rcm
  module Helper
    def find_node_by(name : String, nodes : Array(NodeInfo)) : NodeInfo
      raise "[BUG] empty node name! (find_node_by)" if name.empty?
      
      nodes.each do |node|
        if node.sha1 =~ /\A#{name}/
          return node
        end
      end
      possible = nodes.map(&.sha1_6).join(", ")
      raise "node not found: named `#{name}`\n(possible: #{possible})"
    end

    def master_addr(node, nodes) : String
      find_node_by(node.master, nodes).addr rescue "(#{node.sha1_6})"
    end
  end
end
