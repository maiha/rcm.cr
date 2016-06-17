module Rcm
  module Show::Nodes
    abstract def redis : Connection

    private def build_slave_deps(nodes) : Hash(NodeInfo, Array(NodeInfo))
      slaves = {} of NodeInfo => Array(NodeInfo)
      nodes.each do |node|
        if node.slave? && !node.master.empty?
          master = find_node_by(node.master, nodes)
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

    private def show_node(nodes, node, slaves, shown)
      return if shown.includes?(node)

      mark = node.status.split(",").map(&.sub("disconnected", "!").sub("connected", "*")).join
      role = node.slave? ? "  +slave" : node.role
      addr = "[#{node.addr}]"
      alen = nodes.map(&.addr.size).max

      info = node.slot
      info = "(slave of #{master_addr(node, nodes)})" if node.slave?
      
      print "%s %-#{alen+4}s " % [node.sha1_6, addr]
      buf = "%6s%-5s %s" % [role, "(#{mark})", info]

      if node.fail?
        puts "#{buf}".colorize.red
      elsif node.disconnected?
        puts "#{buf}".colorize.yellow
      elsif node.master? && node.slot?
        puts "#{buf}".colorize.green
        slaves[node]?.try(&.each{|slave| show_node(nodes, slave, slaves, shown)})
      elsif node.slave?
        puts "#{buf}".colorize.cyan
      elsif node.master?
        puts "#{buf}"
      else
        puts "#{buf} (unknown status)".colorize.red
      end
      shown.add(node)
    end

    protected def do_nodes
      do_pretty_nodes(redis.nodes)
    end    

    protected def do_pretty_nodes(buf : String)
      nodes  = Array(NodeInfo).parse(buf)
      slaves = build_slave_deps(nodes)
      shown  = Set(NodeInfo).new

      # first, render masters
      slaves.keys.sort_by(&.addr).each do |node|
        show_node(nodes, node, slaves, shown)
      end

      # render all nodes (dup is skipped by shown cache)
      nodes.each do |node|
        show_node(nodes, node, slaves, shown)
      end
    end
  end
end
