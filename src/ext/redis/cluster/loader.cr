module Redis::Cluster
  def self.load_info(addrs : Array(Addr), pass = nil) : ClusterInfo
    addrs.each do |addr|
      redis = nil
      begin
        redis = Redis.new(addr.host, addr.port, pass)
        return ClusterInfo.parse(redis.not_nil!.nodes)
      rescue
      ensure
        redis.try(&.close)
      end
    end
    raise "Redis not found: #{addrs.map(&.to_s).inspect}"
  end
end
