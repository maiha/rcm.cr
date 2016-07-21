module Redis::Cluster::Pool
  include Enumerable(Redis)     # for all redis connections

  def new_redis(node : NodeInfo)
    Redis.new(host: node.host, port: node.port, password: @password)
  end
  
  def redis(node : NodeInfo)
    @node2redis[node] ||= new_redis(node)
  end

  def redis(key : String)
    redis(node(key))
  end

  def node(key : String)
    slot = Slot.slot(key)
    return @slot2nodes.fetch(slot) { raise "This cluster doesn't cover slot=#{slot} (key=#{key.inspect})" }
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
