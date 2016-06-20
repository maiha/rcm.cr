module Rcm::Cluster
  class ShowInfos
    delegate cluster_info, to: @client
    delegate nodes, slave_deps, master_addr, to: cluster_info

    def initialize(@client : Client)
    end

    def show(io : IO, field : String)
      infos = @client.info(field)
      show_infos(io, infos)
    end
    
    private def show_info(io : IO, node, info, head)
      io.print head.call(node)
      io.puts info.join(", ")
    end

    protected def show_infos(io : IO, infos)
      alen = nodes.map(&.addr.size).max

      head = ->(n : NodeInfo){ "%s [%-#{alen}s]  " % [n.sha1_6, n.addr] }
      nodes.sort_by(&.addr).each do |node|
        show_info(io, node, infos[node], head)
      end
    end
  end
end
