module Rcm::Cluster
  class ShowNodes
    delegate cluster_info, to: @client
    delegate nodes, slave_deps, master_addr, to: cluster_info

    def initialize(@client : Client)
    end

    def initialize(info : ClusterInfo)
      initialize(Client.new(info))
    end

    def show(io : IO, count : Bool = false)
      counts = count ? @client.counts : Hash(NodeInfo, Int64).new
      show_nodes(io, counts)
    end
    
    private def show_node(io : IO, node, slaves, shown, counts)
      return if shown.includes?(node)

      mark = node.status.split(",").map(&.sub("disconnected", "!").sub("connected", "*")).join
      role = node.slave? ? "  +slave" : node.role
      addr = "[#{node.addr}]"
      alen = nodes.map(&.addr.size).max

      info = node.slot
      info = "(slave of #{master_addr(node)})" if node.slave?

      cnt  = counts.fetch(node) { "?" }
      clen = counts.values.map(&.to_s.size).max? || 1

      head = "%s %-#{alen}s(%#{clen}s)  " % [node.sha1_6, addr, cnt]
      body = "%6s%-5s %s" % [role, "(#{mark})", info]

      # colorize down node as RED where cnt == -1
      head = head.colorize.red if cnt == -1
      io.print head
      
      if node.fail?
        io.puts "#{body}".colorize.red
      elsif node.disconnected?
        io.puts "#{body}".colorize.yellow
      elsif node.master? && node.slot?
        io.puts "#{body}".colorize.green
        slaves[node]?.try(&.each{|slave| show_node(io, slave, slaves, shown, counts)})
      elsif node.slave?
        io.puts "#{body}".colorize.cyan
      elsif node.master?
        io.puts "#{body}"
      else
        io.puts "#{body} (unknown status)".colorize.red
      end
      shown.add(node)
    end

    protected def show_nodes(io : IO, counts)
      slaves = slave_deps
      shown  = Set(NodeInfo).new

      # first, render masters where slot exists
      nodes.select(&.slot?).sort_by(&.first_slot).each do |node|
        show_node(io, node, slaves, shown, counts)
      end

      # then, render all nodes (dup is skipped by shown cache)
      nodes.each do |node|
        show_node(io, node, slaves, shown, counts)
      end
    end
  end
end
