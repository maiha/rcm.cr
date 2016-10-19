module Rcm::Cluster
  class ShowNodesList
    include NodesHelper

    delegate nodes, master_addr, to: @info

    property counts, info

    def initialize(@info : ClusterInfo, @counts : Counts, @verbose = false)
      @alen = nodes.map(&.addr.size).max.as(Int32)
      @clen = counts.values.map(&.to_s.size).max? || 1
    end

    def show(io : IO)
      show_nodes_list(io)
    end

    private def node_mark(node)
      node.status.split(",").map(&.sub("disconnected", "!").sub("connected", "*")).join
    end

    private def show_node(io : IO, node, shown, orphaned_master = false, orphaned_slave = false)
      return if shown.includes?(node)

      sha1 = node.sha1_6
      addr = "%-#{@alen}s" % "[#{node.addr}]"
      cnt  = "(%#{@clen}s)" % counts.fetch(node) { "?" }
      head = "#{sha1} #{addr}#{cnt}  "
      
      sloted   = "[%-11s] " % node.slot if node.slot?
      orphaned = "orphaned " if orphaned_master || orphaned_slave

      name = node.role
      name = "standalone #{name}" if node.standalone?
      name = "  +#{name}" if node.slave? && ! orphaned_slave
      
      label = "%s(%s)" % [name, node_mark(node)]
      
      body =
        if orphaned_master || orphaned_slave || node.serving?
          "#{sloted}#{orphaned}#{label}"
        elsif node.slave? || node.standalone?
          "#{label}"
        else
          "#{label}(unknown status)"
        end
      info = " of #{master_addr(node)}" if node.slave?

      if node.fail? || (counts.fetch(node, 0) == -1)
        io.puts "#{head}#{body}#{info}".colorize.red
      elsif node.disconnected?
        io << head
        io.puts "#{body}#{info}".colorize.yellow
      elsif orphaned_master
        io << head
        io.puts "#{body}#{info}".colorize.yellow
      elsif orphaned_slave
        io.puts "#{head}#{body}#{info}".colorize.yellow
      elsif node.serving?
        io << head
        io.puts "#{body}#{info}".colorize.green
      elsif node.slave?
        io.print head
        io.puts "#{body}#{info}".colorize.cyan
      elsif node.standalone?
        io << head
        io.puts "#{body}#{info}"
      else
        io << head
        io.puts "#{body}#{info}".colorize.red
      end
      shown.add(node)
    end

    private def show_nodes_list(io : IO)
      shown = Set(NodeInfo).new

      # first, render serving masters and those slaves
      info.each_serving_masters_with_slaves do |master, slaves|
        show_node(io, master, shown, orphaned_master: slaves.empty?)
        sort_slaves(slaves).each{|slave| show_node(io, slave, shown)}
      end

      # then, render orphaned slaves
      info.orphaned_slaves.each do |slave|
        show_node(io, slave, shown, orphaned_slave: true)
      end
      
      # finaly, render all rest nodes (dup is skipped by shown cache)
      nodes.each do |node|
        show_node(io, node, shown)
      end
    end
  end
end
