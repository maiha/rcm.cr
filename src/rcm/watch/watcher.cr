class Rcm::Watch::Watcher(T)
  @redis : Redis?

  def initialize(@ch : Channel(T), @factory : -> Redis, @command : Proc(Redis, T), @failure : Proc(Exception, T))
  end

  def start(interval)
    spawn do
      schedule_each(interval) { process }
    end
  end

  private def process
    establish_connection!
    @ch.send @command.call(redis!)
  rescue err
    begin
      @ch.send @failure.call(err)
      @redis.try(&.close)
      @redis = nil
    rescue err
      Watch.die(err)
    end
  end

  private def redis!
    @redis.not_nil!
  end

  private def establish_connection!
    @redis ||= @factory.call
  end
end
