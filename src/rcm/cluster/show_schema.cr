module Rcm::Cluster
  class ShowSchema
    include NodesHelper

    delegate nodes, to: @info

    property info

    def initialize(@info : ClusterInfo)
    end

    def show(io : IO)
      show_schema(io)
    end

    ######################################################################
    ### verobse output

    private def show_schema(io : IO)
      info.each_serving_masters_with_slaves do |master, slaves|
        slot = "[%-11s]" % master.slot
        node = ([master] + sort_slaves(slaves)).map(&.addr.to_s).join(" ")
        io.puts "%s %s" % [slot, node]
      end
    end
  end
end
