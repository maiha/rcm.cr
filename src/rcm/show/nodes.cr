module Rcm
  module Show::Nodes
    private def build_slaves(nodes) : Hash(NodeInfo, Array(NodeInfo))
      slaves = {} of NodeInfo => Array(NodeInfo)
      nodes.each do |node|
        if node.slave? && !node.master.empty?
          master = redis.find_node_by(node.master)
          slaves[master] ||= [] of NodeInfo
          slaves[master] << node
        end
      end
      return slaves
    end

    private def show_node(node, slaves, shown)
      return if shown.includes?(node)

      mark = node.online? ? "(*)" : ""
      role = node.slave? ? "  +slave" : node.role
      buf = "[%s](%s) %6s%-5s %s" %
            [node.sha1_6, node.addr, role, mark, node.slot]
      if !node.online?
        puts "#{buf}".colorize.yellow
      elsif node.master? && node.slot?
        puts "#{buf}".colorize.green
        slaves[node]?.try(&.each{|slave| show_node(slave, slaves, shown)})
      elsif node.slave?
        master = redis.find_node_by(node.master).addr rescue node.sha1_6
        puts "#{buf}(connected #{master})".colorize.cyan
      elsif node.master?
        puts "#{buf}"
      else
        puts "#{buf} (unknown status)".colorize.red
      end
      shown.add(node)
    end
    
    protected def show_nodes
      nodes  = redis.nodes
      slaves = build_slaves(nodes)
      shown  = Set(Rcm::NodeInfo).new

      nodes.each do |node|
        show_node(node, slaves, shown)
      end
    end
  end
end
