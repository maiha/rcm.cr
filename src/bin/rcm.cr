require "../rcm"
require "../options"
require "colorize"

class Rcm::Main
  include Options
  include Show::Nodes
  include Rcm::Helper

  option host  : String, "-h <hostname>", "Server hostname", "127.0.0.1"
  option port  : Int32 , "-p <port>", "Server port", 6379
  option pass  : String?, "-a <password>", "Password to use when connecting to the server", nil
  option help  : Bool  , "--help", "Output this help and exit", false
  
  usage <<-EOF
    #{$0} version 0.1.0

    Usage: #{$0} <commands>

    Options:

    Commands:
      nodes               Print nodes information
      meet <host> <port>  Join the cluster on <host>:<port>
      replicate <master>  Configure node as replica of the <master>
      pretty_nodes        Same as `nodes` except this reads from stdin (offline mode)

    Example:
      #{$0}     nodes
      #{$0}     meet 127.0.0.1 7001
      #{$0}     replicate 2afb4d
      redis-cli cluster nodes | #{$0} pretty_nodes
    EOF

  def run
    args                        # kick parse!
    if help
      STDERR.puts usage
      exit 0
    end

    op = args.shift { die "command not found!" }

    case op
    when "nodes"
      do_nodes
      
    when "meet"
      host = args.shift { die "meet expects <host> <port>" }
      port = args.shift { die "meet expects <host> <port>" }
      puts "MEET #{host} #{port}"
      puts redis.meet(host, port)
      
    when "replicate"
      name = args.shift { die "replicate expects <master>" }
      node = find_node_by(name, Array(NodeInfo).parse(redis.nodes))
      puts "REPLICATE #{node.addr}"
      puts redis.replicate(node)

    when "pretty_nodes"
      begin
        do_pretty_nodes(ARGF.gets_to_end)
      rescue err : Errno
        die(err.to_s)
      end
      
    else
      die "unknown command: #{op}"
    end
  rescue err
    STDERR.puts err.to_s.colorize(:red)
    suggest_for_error(err)
    exit 1
  ensure
    redis.close if @redis
  end

  private def redis
    @redis ||= Rcm::Client.new(host, port, pass)
  end

  private def suggest_for_error(err)
    case err.to_s
    when /NOAUTH Authentication required/
      STDERR.puts "try `-a` option: '#{$0} -a XXX'"
    end
  end
end

Rcm::Main.new.run


