require "./commands"

class Rcm::Client
  property info, node2redis
  
  def initialize(@info : ClusterInfo, @password : String? = nil)
    @slot2nodes = @info.slot2nodes.as(Hash(UInt16, NodeInfo))
    @node2redis = Hash(NodeInfo, Redis).new
  end

  include Rcm::Commands

  def redis(node : NodeInfo)
    @node2redis[node] ||= Redis.new(host: node.host, port: node.port, password: @password)
  end

  def redis(key : String)
    slot = Rcm.slot(key)
    node = @slot2nodes.fetch(slot) { raise "[BUG] node not found for slot:#{slot}" }
    redis(node)
  end

  def counts
    @info.nodes.reduce(Hash(NodeInfo, Int64).new) do |h, n|
      h[n] = redis(n).count
      h
    end
  end
  
  def cover_slot?(slot)
    !! @slot2nodes[slot]?
  end

  def close
    @node2redis.values.each(&.close)
    @node2redis.clear
  end
end
