module Rcm
  module Commands
    def nodes
      string_command(["CLUSTER", "NODES"])
    end
    
    def meet(host : String, port : String)
      string_command(["CLUSTER", "MEET", host, port])
    end

    def replicate(node : NodeInfo)
      string_command(["CLUSTER", "REPLICATE", node.sha1])
    end
  end
end
