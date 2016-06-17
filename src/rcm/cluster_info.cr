module Rcm
  record ClusterInfo,
    nodes  : Array(NodeInfo) do

    def slave_deps
      build_slave_deps
    end

    def find_node_by(name : String) : NodeInfo
      raise "[BUG] empty node name! (find_node_by)" if name.empty?
      
      nodes.each do |node|
        if node.sha1 =~ /\A#{name}/
          return node
        end
      end
      possible = nodes.map(&.sha1_6).join(", ")
      raise "node not found: named `#{name}`\n(possible: #{possible})"
    end

    def master_addr(node) : String
      find_node_by(node.master).addr rescue "(#{node.sha1_6})"
    end
    
    private def build_slave_deps : Hash(NodeInfo, Array(NodeInfo))
      slaves = {} of NodeInfo => Array(NodeInfo)
      nodes.each do |node|
        if node.slave? && !node.master.empty?
          master = find_node_by(node.master)
          slaves[master] ||= [] of NodeInfo
          slaves[master] << node
        end
      end

      # remove past masters that is regarded as a master but is now a slave
      slaves.keys.each do |node|
        slaves.delete(node) if node.slave?
      end
      
      return slaves
    end
  end
end
