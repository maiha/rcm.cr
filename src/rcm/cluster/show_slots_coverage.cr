module Rcm::Cluster
  class ShowSlotsCoverage
    delegate nodes, open_slots, to: @info

    def initialize(@info : ClusterInfo)
    end

    def show(io : IO)
      show_slots_coverage(io)
    end

    private def show_slots_coverage(io : IO)
      open = open_slots
      if open.empty?
        # [OK] All 16384 slots covered.
        m = @info.serving_masters.size
        s = @info.slaves.size
        io.puts "[OK] All 16384 slots are covered by #{m} masters and #{s} slaves.".colorize.green
      else
        # [ERR] Not all 16384 slots are covered by nodes.
        cold = 16384 - open.size
        pct  = cold * 100.0 / 16384
        rate = "%.1f" % pct
        rate = "99.9" if rate == "100.0" && open.size > 0
        info = open[0..3].join(",") + ((open.size > 3) ? ",..." : "")
        mes  = "[COVERAGE] %s%%(%d/16384) slots are covered. (open slots: %s)" % [rate, cold, info]
        io.puts mes.colorize.red
      end
    end
  end
end
