require "http/server"

module Rcm::Httpd
  class Server
    def initialize(@redis : ::Redis::Client, @listen : Bootstrap)
      Kemal.config.add_handler RedisHandler.new(@redis, watch_interval: 1.second)
      pass = @redis.password || @listen.pass
      if pass
        auth_handler = Kemal::Middleware::HTTPBasicAuth.new("redis", pass)
        Kemal.config.add_handler auth_handler
      end
    end
    
    def start
      puts "Listening on http://#{@listen.host}:#{@listen.port}"
      Kemal.run
    end
  end  
end
