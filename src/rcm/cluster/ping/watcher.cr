class Rcm::Cluster::Ping::Watcher
  @redis : Redis?

  def initialize(@node : NodeInfo, @factory : -> Redis, @ch : Channel::Unbuffered(Result))
  end

  def start(interval)
    spawn do
      schedule_each(1.second) { ping }
    end
  end

  def ping
    establish_connection!
    count = redis!.count!
    @ch.send Result.new(@node, Time.now, count)
  rescue
    @ch.send Result.new(@node, Time.now, -1_i64)
    @redis.try(&.close)
    @redis = nil
  end

  private def redis!
    @redis.not_nil!
  end

  private def establish_connection!
    @redis ||= @factory.call
  end
end
