require "redis"

class Redis
  module Commands
    def nodes
      string_command(["CLUSTER", "NODES"])
    end
    
    def meet(host : String, port : String)
      string_command(["CLUSTER", "MEET", host, port])
    end

    def replicate(master : String)
      string_command(["CLUSTER", "REPLICATE", master])
    end
  end
end
