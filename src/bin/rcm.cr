require "../rcm"
require "../options"
require "colorize"
require "crt"

class Rcm::Main
  include Options

  option host  : String, "-h <hostname>", "Server hostname", "127.0.0.1"
  option port  : Int32 , "-p <port>", "Server port", 6379
  option pass  : String?, "-a <password>", "Password to use when connecting to the server", nil
  option yes   : Bool, "--yes", "Accept advise automatically", false
  option nocrt : Bool, "--nocrt", "Use STDIO rather than experimental CRT", false
  option verbose : Bool, "-v", "Enable verbose output", false
  option help  : Bool  , "--help", "Output this help and exit", false
  
  usage <<-EOF
    #{$0} version 0.1.4

    Usage: #{$0} <commands>

    Options:

    Commands:
      nodes (file)        Print nodes info from file or server
      info <field>        Print given field from INFO for all nodes
      ping                Ping to all nodes
      addslots <slots>    Add slots to the node
      meet <master>       Join the cluster on <master>
      replicate <master>  Configure node as replica of the <master>
      get <key>           Get specified data from the cluster
      set <key> <val>     Set specified data to the cluster
      import <tsv file>   Test data import from tsv file
      advise (--yes)      Print advises. Execute them when --yes given

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
    when /^nodes$/i
      info = ClusterInfo.parse(args.any? ? safe{ ARGF.gets_to_end } : redis.nodes)
      counts = Client.new(info, pass).counts
      Cluster::ShowNodes.new(info, counts, verbose: verbose).show(STDOUT)

    when /^info$/i
      field = (args.empty? || args[0].empty?) ? "v,cnt,m,d" : args[0]
      Cluster::ShowInfos.new(client).show(STDOUT, field: field)

    when /^ping$/i
      Cluster::Ping.ping(client, crt: !nocrt)

    when /^addslots$/i
      slot = Slot.parse(args.join(","))
      die "addslots expects <slot range> # ex. 'addslot 0-16383'" if slot.empty?
      puts "ADDSLOTS #{slot.to_s} (total: #{slot.size} slots)"
      puts redis.addslots(slot.slots)
      
    when /^meet$/i
      host = args.shift { die "meet expects <master> # ex. 'meet 127.0.0.1:7001'" }
      addr = Addr.parse(host)
      puts "MEET #{addr.host} #{addr.port}"
      puts redis.meet(addr.host, addr.port.to_s)
      
    when /^replicate$/i
      name = args.shift { die "replicate expects <master>" }
      info = ClusterInfo.parse(redis.nodes)
      node = info.find_node_by!(name)
      puts "REPLICATE #{node.addr}"
      puts redis.replicate(node.sha1)

    when /^get$/i
      key = args.shift { die "get expects <key>" }
      val = client.get(key)
      puts val.nil? ? "(nil)" : val.inspect

    when /^set$/i
      key = args.shift { die "set expects <key> <val>" }
      val = args.shift { die "get expects <key> <val>" }
      client.set(key, val)

    when /^import$/i
      name = args.shift { die "import expects <tsv-file>" }
      file = safe{ File.open(name) }
      info = ClusterInfo.parse(redis.nodes)
      step = Cluster::StepImport.new(Client.new(info, pass))
      step.import(file, delimiter: "\t", progress: true, count: 1000)
      
    when /^advise$/i
      replica = Advise::BetterReplication.new(client.cluster_info, client.counts)
      if replica.advise?
        if yes
          puts "#{Time.now}: BetterReplication: #{replica.impact}"
          replica.advises.each do |a|
            puts a.cmd
            system(a.cmd)
          end
        else
          Cluster::ShowAdviseBetterReplication.new(replica).show(STDOUT)
        end
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
