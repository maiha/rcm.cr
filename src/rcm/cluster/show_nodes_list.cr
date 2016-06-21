module Rcm::Cluster
  class ShowNodesList
    delegate nodes, slave_deps, master_addr, open_slots, to: @info

    property counts, info

    def initialize(@info : ClusterInfo, @counts : Counts)
    end

    def show(io : IO)
      show_nodes_list(io)
    end

    private def node_role(node)
      return "standalone" if node.standalone?
      return "  +slave" if node.slave?
      return node.role
    end

    private def show_node(io : IO, node, slaves, shown)
      return if shown.includes?(node)

      mark = node.status.split(",").map(&.sub("disconnected", "!").sub("connected", "*")).join
      addr = "[#{node.addr}]"
      alen = nodes.map(&.addr.size).max

      info = node.slot
      info = "(slave of #{master_addr(node)})" if node.slave?

      cnt  = counts.fetch(node) { "?" }
      clen = counts.values.map(&.to_s.size).max? || 1

      head = "%s %-#{alen}s(%#{clen}s)  " % [node.sha1_6, addr, cnt]
      body = "%6s%-5s %s" % [node_role(node), "(#{mark})", info]

      # colorize down node as RED where cnt == -1
      head = head.colorize.red if cnt == -1
      io.print head
      
      if node.fail?
        io.puts "#{body}".colorize.red
      elsif node.disconnected?
        io.puts "#{body}".colorize.yellow
      elsif node.master? && node.slot?
        io.puts "#{body}".colorize.green
        slaves[node]?.try(&.each{|slave| show_node(io, slave, slaves, shown)})
      elsif node.slave?
        io.puts "#{body}".colorize.cyan
      elsif node.standalone?
        io.puts "#{body}"
      else
        io.puts "#{body} (unknown status)".colorize.red
      end
      shown.add(node)
    end

    private def show_nodes_list(io : IO)
      slaves = slave_deps
      shown  = Set(NodeInfo).new

      # first, render masters where slot exists
      info.serving_masters.each do |node|
        show_node(io, node, slaves, shown)
      end

      # then, render all nodes (dup is skipped by shown cache)
      nodes.each do |node|
        show_node(io, node, slaves, shown)
      end
    end
  end
end
