module Rcm::Cluster
  class ShowStatus
    delegate nodes, master_addr, to: @info

    property info, counts

    def initialize(@info : ClusterInfo, @counts : Counts, @verbose = false)
    end

    def show(io : IO)
      if @verbose
        show_verbose_status(io)
      else
        show_status(io)
      end
    end

    private def show_status(io : IO)
      info.each_serving_masters_with_slaves do |master, slaves|
        sloted_str = build_slot(master, slaves)
        status_str = build_status(master, slaves)
        io.puts "%s %s" % [sloted_str, status_str]
      end
    end

    private def down?(node)
      node.fail? || (counts.fetch(node, 0) == -1)
    end

    private def orphaned?(master, slaves)
      return true if slaves.select{|n| !down?(n)}.empty?
      return false
    end

    private def build_slot(master, slaves)
      label = "[%-11s]" % master.slot
      return label.colorize.red if down?(master)
      return label.colorize.yellow if orphaned?(master, slaves)
      return label.colorize.green
    end

    private def build_status(master, slaves)
      return "down(#{master.addr})".colorize.red if down?(master)

      ok_slaves = slaves.select{|n| !down?(n)}.size
      case ok_slaves
      when 0
        return "orphaned master(#{master.addr})".colorize.yellow
      else
        return "master(#{master.addr}) with #{ok_slaves} slaves".colorize.green
      end
    end

    ######################################################################
    ### verobse output

    private def show_verbose_status(io : IO)
      info.each_serving_masters_with_slaves do |master, slaves|
        sloted_str = build_slot(master, slaves)
        status_str = build_verbose_status(master, slaves)
        io.puts "%s %s" % [sloted_str, status_str]
      end
    end

    private def build_verbose_status(master, slaves)
      master_str = build_master(master, slaves)
      slaves_str = build_slaves(master, slaves)
      return "%s %s" % [master_str, slaves_str]
    end

    private def build_master(master, slaves)
      label = "M(%s)" % master.addr
      return label.colorize.red if down?(master)
      return label.colorize.yellow if slaves.select{|n| !down?(n)}.empty?
      return label.colorize.green
    end

    private def build_slaves(master, slaves)
      if slaves.empty?
        return "(orphaned)"
      else
        return slaves.map{|s| build_slave(s) }.join(" ")
      end
    end

    private def build_slave(slave)
      label = "S(%s)" % slave.addr
      return label.colorize.red if down?(slave)
      return label.colorize.cyan
    end
  end
end
