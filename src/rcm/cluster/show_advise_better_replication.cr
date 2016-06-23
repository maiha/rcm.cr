module Rcm::Cluster
  class ShowAdviseBetterReplication
    delegate nodes, to: @info

    def initialize(@info : ClusterInfo, @counts : Counts)
    end

    def show(io : IO)
      show_advise_better_replication(io)
    end

    private def show_advise_better_replication(io : IO)
      adviser = Rcm::Advise::BetterReplication.new(@info, @counts)
      if adviser.advise?
        io.puts "advise: This can provide better replication. (#{adviser.impact})".colorize.yellow
        adviser.advises.each do |a|
          io.puts "  #{a}".colorize.yellow
        end
      end
    end
  end
end
