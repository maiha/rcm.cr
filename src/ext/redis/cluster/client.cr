require "./commands"
require "./pool"

class Redis::Cluster::Client
  property cluster_info
  property node2redis

  delegate nodes, to: @cluster_info

  def initialize(@cluster_info : ClusterInfo, @password : String? = nil)
    @slot2nodes = @cluster_info.slot2nodes.as(Hash(Int32, NodeInfo))
    @node2redis = Hash(NodeInfo, Redis).new
  end

  include Redis::Commands
  include Redis::Cluster::Commands
  include Redis::Cluster::Pool
end
