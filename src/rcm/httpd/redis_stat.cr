module Rcm::Httpd::RedisStat
  include Redis::Cluster

  record StatError,
    addr  : Addr,
    error : Exception

  record StatFound,
    addr   : Addr,
    used   : String,
    max    : String,
    pct    : Int32,
    policy : String do

    def self.parse(n, hash)
      StatFound.new(
        addr: n.addr,
        used: hash.fetch("used_memory_human") { "?" },
        max: hash.fetch("maxmemory_human") { "?" },
        pct: [(hash["used_memory"].to_i64 * 100 / hash["maxmemory"].to_i64).ceil, 100].min.to_i32,
        policy: hash["maxmemory_policy"],
      )
    rescue err
      error(n, err)
    end
    
    def self.error(n, err)
      StatError.new(n.addr, err)
    end
  end

  alias Stat = StatFound | StatError
end
