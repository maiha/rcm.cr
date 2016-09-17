require "colorize"
require "../../watch/*"

class Rcm::Httpd::Watchdog::Info
  include Redis::Cluster
  include Rcm::Watch
  include RedisStat

  property stats   : Hash(Addr, Stat) = Hash(Addr, Stat).new
  property channel : Channel::Unbuffered(Stat) = Channel::Unbuffered(Stat).new
  property agents  : Array(Watcher(Stat))

  def initialize(client : ::Redis::Client, @interval : Time::Span)
    # copy connection for async use
    @client = ::Redis::Client.new(client.host, client.port, client.password)
    @client.ping
    @agents = build_agents(@client.cluster)
  end

  def start
    start_server
    start_agents
  end

  private def start_server
    spawn do
      loop {
        select
        when stat = @channel.receive
          @stats[stat.addr] = stat
        end
      }
    end
  end

  private def start_agents
    @agents.each(&.start(@interval))
  end

  private def build_agents(client : ::Redis::Cluster::Client)
    client.nodes.map{|n|
      Watcher(Stat).new(@channel,
        factory: new_redis_proc(client, n),
        command: ->(redis : Redis) { StatFound.parse(n, redis.info) },
        failure: ->(e : Exception) { StatError.new(n.addr, e).as(Stat) },
      )
    }
  end

  # TODO: leak connection?
  private def new_redis_proc(client, node : Redis::Cluster::NodeInfo)
    ->() { client.new_redis(node.host, node.port) }
  end
#        STDERR.puts "#{Time.now}: #{self.class} #{err}".colorize.red
end
