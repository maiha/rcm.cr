require "./commands"

class Rcm::Client
  property cluster_info, node2redis
  delegate nodes, to: @cluster_info
  
  def initialize(@cluster_info : ClusterInfo, @password : String? = nil)
    @slot2nodes = @cluster_info.slot2nodes.as(Hash(UInt16, NodeInfo))
    @node2redis = Hash(NodeInfo, Redis).new
  end

  include Enumerable(Redis)     # for all redis connections
  include Rcm::Commands

  def redis(node : NodeInfo)
    @node2redis[node] ||= Redis.new(host: node.host, port: node.port, password: @password)
  end

  def redis(key : String)
    slot = Rcm.slot(key)
    node = @slot2nodes.fetch(slot) { raise "[BUG] node not found for slot:#{slot}" }
    redis(node)
  end

  def each
    @cluster_info.nodes.each do |n|
      yield redis(n)
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
