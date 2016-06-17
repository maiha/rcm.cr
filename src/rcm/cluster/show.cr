module Rcm::Cluster
  class ShowNodes
    delegate nodes, slave_deps, master_addr, to: @info

    def initialize(@info : ClusterInfo)
    end

    def show
      do_pretty_nodes
    end
    
    private def show_node(node, slaves, shown)
      return if shown.includes?(node)

      mark = node.status.split(",").map(&.sub("disconnected", "!").sub("connected", "*")).join
      role = node.slave? ? "  +slave" : node.role
      addr = "[#{node.addr}]"
      alen = nodes.map(&.addr.size).max

      info = node.slot
      info = "(slave of #{master_addr(node)})" if node.slave?
      
      print "%s %-#{alen+4}s " % [node.sha1_6, addr]
      buf = "%6s%-5s %s" % [role, "(#{mark})", info]

      if node.fail?
        puts "#{buf}".colorize.red
      elsif node.disconnected?
        puts "#{buf}".colorize.yellow
      elsif node.master? && node.slot?
        puts "#{buf}".colorize.green
        slaves[node]?.try(&.each{|slave| show_node(slave, slaves, shown)})
      elsif node.slave?
        puts "#{buf}".colorize.cyan
      elsif node.master?
        puts "#{buf}"
      else
        puts "#{buf} (unknown status)".colorize.red
      end
      shown.add(node)
    end

    protected def do_pretty_nodes
      slaves = slave_deps
      shown  = Set(NodeInfo).new

      # first, render masters
      slaves.keys.sort_by(&.addr).each do |node|
        show_node(node, slaves, shown)
      end

      # render all nodes (dup is skipped by shown cache)
      nodes.each do |node|
        show_node(node, slaves, shown)
      end
    end
  end
end
