module Rcm::Cluster
  class ShowNodes
    def initialize(@info : ClusterInfo, @counts : Counts, @verbose = false)
    end

    def show(io : IO)
      ShowNodesList.new(@info, @counts, verbose: @verbose).show(io)
      ShowSlotsCoverage.new(@info, @counts).show(io)
      ShowSlotsService.new(@info, @counts, verbose: @verbose).show(io)
      ShowAdviseBetterReplication.new(@info, @counts).show(io)
    end
  end
end
