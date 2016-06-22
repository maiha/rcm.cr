module Rcm::Cluster
  class ShowNodes
    def initialize(@info : ClusterInfo, @counts : Counts, @verbose = false)
    end

    def show(io : IO)
      ShowNodesList.new(@info, @counts, verbose: @verbose).show(io)
      ShowSlotsCoverage.new(@info).show(io)
      ShowSlotsService.new(@info, @counts, verbose: @verbose).show(io)
    end
  end
end
