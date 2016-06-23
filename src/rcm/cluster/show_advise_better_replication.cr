module Rcm::Cluster
  class ShowAdviseBetterReplication
    def initialize(@adviser : Advise::BetterReplication)
    end

    def initialize(info : ClusterInfo, counts : Counts)
      initialize(Rcm::Advise::BetterReplication.new(info, counts))
    end

    def show(io : IO)
      show_advise_better_replication(io)
    end

    private def show_advise_better_replication(io : IO)
      if @adviser.advise?
        io.puts "advise: This can provide better replication. (#{@adviser.impact})".colorize.yellow
        @adviser.advises.each do |a|
          io.puts "  #{a}".colorize.yellow
        end
      end
    end
  end
end
