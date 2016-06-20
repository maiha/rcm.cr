require "../rcm"
require "../options"
require "colorize"

class Rcm::Main
  include Options

  option host  : String, "-h <hostname>", "Server hostname", "127.0.0.1"
  option port  : Int32 , "-p <port>", "Server port", 6379
  option pass  : String?, "-a <password>", "Password to use when connecting to the server", nil
  option help  : Bool  , "--help", "Output this help and exit", false
  
  usage <<-EOF
    #{$0} version 0.1.2

    Usage: #{$0} <commands>

    Options:

    Commands:
      nodes (file)        Print nodes info from file or server
      info <field>        Print given field from INFO for all nodes
      meet <master>       Join the cluster on <master>
      replicate <master>  Configure node as replica of the <master>
      import <tsv file>   Test data import from tsv file

    Example:
      #{$0} nodes
      #{$0} info redis_version
      #{$0} meet 127.0.0.1:7001       # or shortly "meet :7001"
      #{$0} replicate 127.0.0.1:7001  # or shortly "replicate :7001"
      #{$0} import foo.tsv
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
      info = ClusterInfo.parse(args.any? ? safe{ ARGF.gets_to_end } : redis.nodes)
      Cluster::ShowNodes.new(Client.new(info, pass)).show(STDOUT, count: true)

    when "info"
      field = (args.empty? || args[0].empty?) ? "v,cnt,m,d" : args[0]
      Cluster::ShowInfos.new(client).show(STDOUT, field: field)

    when "meet"
      host = args.shift { die "meet expects <master> # ex. 'meet 127.0.0.1:7001'" }
      addr = Addr.parse(host)
      puts "MEET #{addr.host} #{addr.port}"
      puts redis.meet(addr.host, addr.port.to_s)
      
    when "replicate"
      name = args.shift { die "replicate expects <master>" }
      info = ClusterInfo.parse(redis.nodes)
      node = info.find_node_by(name)
      puts "REPLICATE #{node.addr}"
      puts redis.replicate(node.sha1)

    when "import"
      name = args.shift { die "import expects <tsv-file>" }
      file = safe{ File.open(name) }
      info = ClusterInfo.parse(redis.nodes)
      step = Cluster::StepImport.new(Client.new(info, pass))
      step.import(file, delimiter: "\t", progress: true, count: 1000)
      
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
    @redis ||= Redis.new(host, port, pass)
  end

  private def client
    @client ||= Client.new(ClusterInfo.parse(redis.nodes), pass)
  end
  
  macro safe(klass)
    expect_error({{klass.id}}) { {{yield}} }
  end
  
  macro safe
    expect_error(Exception) { {{yield}} }
  end
  
  private def suggest_for_error(err)
    case err.to_s
    when /NOAUTH Authentication required/
      STDERR.puts "try `-a` option: '#{$0} -a XXX'"
    end
  end
end

Rcm::Main.new.run
