require "redis"

class Redis
  module Commands
    def nodes
      string_command(["CLUSTER", "NODES"])
    end
    
    def addslots(slots : Array(Int32))
      string_command(["CLUSTER", "ADDSLOTS"] + slots.map(&.to_s))
    end

    def meet(host : String, port : String)
      string_command(["CLUSTER", "MEET", host, port])
    end

    def replicate(master : String)
      string_command(["CLUSTER", "REPLICATE", master])
    end

    def count : Int64
      hash = info("Keyspace")
      case hash.fetch("db0") { "" }
      when /^keys=(\d+)/m
        return $1.to_i64
      else
        return 0.to_i64
      end
    rescue err : Errno
      # tcp down: #<Errno:0xd37a40 @message="Error connecting to '127.0.0.1:7001': Connection refused"
      return -1.to_i64
    end
  end
end
