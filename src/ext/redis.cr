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

    def count : Int64
      hash = info("Keyspace")
      case hash["db0"]?
      when nil
        return -1.to_i64
      when /^keys=(\d+)/m
        return $1.to_i64
      else
        return 0.to_i64
      end
    end
  end
end
