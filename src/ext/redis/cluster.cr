require "./commands"

module Redis::Cluster
  alias Counts = Hash(NodeInfo, Int64)

  def self.new(bootstrap : String, password : String? = nil)
    addrs = bootstrap.split(",").map{|s| Addr.parse(s)}
    info  = load_info(addrs, password)
    new(info, password)
  end

  def self.new(info : ClusterInfo, password : String? = nil)
    Client.new(info, password)
  end
end

require "./cluster/**"
