module Rcm::Cluster
  class ShowSlotsService
    property counts, info

    def initialize(@info : ClusterInfo, @counts : Counts, @verbose = false)
    end

    def show(io : IO)
      show_slots_service(io)
    end

    private def dead?(node : NodeInfo) : Bool
      counts.fetch(node, -1) == -1
    end

    private def alive?(node : NodeInfo) : Bool
      ! dead?(node)
    end

    private def show_slots_service(io : IO)
      log = BufferedLogger.new(prefix: "  ")
      log.level = (@verbose ? Logger::DEBUG : Logger::WARN)
      rfs = [] of Int32         # replication factors
      orphaned_master_count = 0

      info.each_serving_masters_with_slaves do |master, slaves|
        active_slaves = slaves.select{|slave| alive?(slave)}
        rfs << (alive?(master) ? 1 : 0) + active_slaves.size
        if dead?(master)
          reason = "SLOT #{master.slot} is not served! (#{master.addr} is dead)"
          if active_slaves.size > 0
            # master is dead, but some slaves are alive. (I don't know this occurs)
            info = active_slaves.map(&.addr.to_s).inspect
            log.error "[??] #{reason}, but slaves exist #{info}"
          else
            # master is dead, and all slaves are also dead
            log.error "[NG] #{reason}, and no slaves"
          end
        else
          if active_slaves.size > 0
            cnt = active_slaves.size
            log.info "[OK] SLOT #{master.slot} is ok with #{cnt} slave(s)"
          else
            orphaned_master_count += 1
            log.warn "[WA] SLOT #{master.slot} is served by orphaned master (#{master.addr})"
          end
        end
      end

      if log.ng?
        io.puts "[Service] Critical! Unavailable slots exists.".colorize.red
        log.flush(io)
      elsif log.wa?
        sample = info.orphaned_masters(counts).map(&.addr.to_s).sort.inspect
        io.puts "[Service] Found #{orphaned_master_count} orphaned master(s). #{sample}".colorize.yellow
        log.flush(io)
      else
        if rfs.size == 0
          io.puts "[Service] No servers.".colorize.yellow
        else
          rf = rfs.min.to_s + (rfs.min < rfs.max ? "+" : "")
          io.puts "[OK] All slots are available with #{rf} replication factor(s).".colorize.green
        end
      end
    end
  end
end
