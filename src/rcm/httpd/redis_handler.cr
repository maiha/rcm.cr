# add new features to core class
# original: https://github.com/sdogruyol/kemal-redis/blob/master/src/kemal-redis.cr
class ::HTTP::Server::Context
  property! redis : ::Redis::Client
  property! info  : Rcm::Httpd::Watchdog::Info
end

class Rcm::Httpd::RedisHandler < HTTP::Handler
  def initialize(@redis : ::Redis::Client, watch_interval : Time::Span)
    @redis.ping
    @info = Rcm::Httpd::Watchdog::Info.new(@redis, watch_interval)
    @info.start
  end

  def call(request)
    request.redis = @redis
    request.info  = @info
    call_next(request)
  end
end
