require "./commands"

class Rcm::Client
  property node2redis

  def initialize(@info : ClusterInfo, @password : String? = nil)
    @slot2nodes = @info.slot2nodes.as(Hash(UInt16, NodeInfo))
    @node2redis = Hash(NodeInfo, Redis).new
  end

  include Rcm::Commands

  def redis(key : String)
    slot = Rcm.slot(key)
    node = @slot2nodes.fetch(slot) { raise "[BUG] node not found for slot:#{slot}" }
    @node2redis[node] ||= Redis.new(host: node.host, port: node.port, password: @password)
  end

  def cover_slot?(slot)
    !! @slot2nodes[slot]?
  end

  def close
    @node2redis.values.each(&.close)
    @node2redis.clear
  end
end
