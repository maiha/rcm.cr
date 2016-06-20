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
      addslots <slots>    Add slots to the node
      meet <master>       Join the cluster on <master>
      replicate <master>  Configure node as replica of the <master>
      get <key>           Get specified data from the cluster
      set <key> <val>     Set specified data to the cluster
      import <tsv file>   Test data import from tsv file

    Example:
      #{$0} nodes
      #{$0} info redis_version
      #{$0} addslots 0-100            # or "0,1,2", "10000-"
      #{$0} meet 127.0.0.1:7001       # or shortly "meet :7001"
      #{$0} replicate 127.0.0.1:7001  # or shortly "replicate :7001"
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

    when "addslots"
      slot = Slot.parse(args.join(","))
      die "addslots expects <slot range> # ex. 'addslot 0-16383'" if slot.empty?
      puts "ADDSLOTS #{slot.to_s} (total: #{slot.size} slots)"
      puts redis.addslots(slot.slots)
      
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

    when "get"
      key = args.shift { die "get expects <key>" }
      val = client.get(key)
      puts val.nil? ? "(nil)" : val.inspect

    when "set"
      key = args.shift { die "set expects <key> <val>" }
      val = args.shift { die "get expects <key> <val>" }
      client.set(key, val)

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
