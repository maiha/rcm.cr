module Rcm::Cluster
  class ShowSchema
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

    # sort slaves by port and host for durability pretty printing
    private def sort_slaves(nodes)
      nodes.sort {|a,b|
        case a.port <=> b.port
        when 0 then a.host <=> b.host
        else a.port <=> b.port
        end
      }
    end
  end
end
