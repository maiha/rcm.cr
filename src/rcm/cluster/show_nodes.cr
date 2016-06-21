module Rcm::Cluster
  class ShowNodes
    def initialize(@info : ClusterInfo, @counts : Counts)
    end

    def show(io : IO)
      ShowNodesList.new(@info, @counts).show(io)
      ShowSlotsCoverage.new(@info).show(io)
      ShowSlotsService.new(@info, @counts).show(io)
    end
  end
end
