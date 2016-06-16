module Rcm
  module Commands
    def nodes
      ret = string_command(["CLUSTER", "NODES"])
      Array(NodeInfo).parse(ret)
    end
    
    def replicate(node : NodeInfo)
      string_command(["CLUSTER", "REPLICATE", node.sha1])
    end

    def find_node_by(name : String) : NodeInfo
      find_node_by(name, nodes)
    end

    def find_node_by(name : String, nodes : Array(NodeInfo)) : NodeInfo
      nodes.each do |node|
        if node.sha1 =~ /\A#{name}/
          return node
        end
      end
      possible = nodes.map(&.sha1_6).join(", ")
      raise "node not found: named `#{name}`\n(possible: #{possible})"
    end
  end
end
