require "../rcm"
require "../options"
require "colorize"
require "crt"

class Rcm::Main
  include Options

  VERSION = "0.3.0"

  option host  : String, "-h <hostname>", "Server hostname", "127.0.0.1"
  option port  : Int32 , "-p <port>", "Server port", 6379
  option pass  : String?, "-a <password>", "Password to use when connecting to the server", nil
  option yes   : Bool, "--yes", "Accept advise automatically", false
  option nop   : Bool, "-n", "Print the commands that would be executed", false
  option nocrt : Bool, "--nocrt", "Use STDIO rather than experimental CRT", false
  option masters : Int32? , "--masters <num>", "[create only] Master num", nil
  option verbose : Bool, "-v", "Enable verbose output", false
  option version : Bool, "--version", "Print the version and exit", false
  option help  : Bool  , "--help", "Output this help and exit", false
  
  usage <<-EOF
    rcm version #{VERSION}

    Usage: rcm <commands>

    Options:

    Commands:
      status              Print cluster status
      nodes (file)        Print nodes info from file or server
      info <field>        Print given field from INFO for all nodes
      watch <sec1> <sec2> Monitor counts of cluster nodes
      create <addr1> ...  Create cluster
      join <addr1> ...    Waiting for the cluster to join
      addslots <slots>    Add slots to the node
      meet <master>       Join the cluster on <master>
      replicate <master>  Configure node as replica of the <master>
      failover            Become master with agreement (slave only)
      takeover            Become master without agreement (slave only)
      get <key>           Get specified data from the cluster
      set <key> <val>     Set specified data to the cluster
      import <tsv file>   Test data import from tsv file
      advise (--yes)      Print advises. Execute them when --yes given

    Example:
      rcm nodes
      rcm info redis_version
      rcm create 192.168.0.1:7001 192.168.0.2:7001 ... --masters 3
      rcm addslots 0-100            # or "0,1,2", "10000-"
      rcm meet 127.0.0.1:7001       # or shortly "meet :7001"
      rcm replicate 127.0.0.1:7001  # or shortly "replicate :7001"
    EOF

  def run
    args                        # kick parse!
    quit(usage) if help
    quit("rcm #{VERSION}") if version

    op = args.shift { die "command not found!" }

    case op
    when /^status$/i
      Cluster::ShowStatus.new(cluster.cluster_info, cluster.counts, verbose: verbose).show(STDOUT)

    when /^nodes$/i
      info = ClusterInfo.parse(args.any? ? safe{ ARGF.gets_to_end } : redis.nodes)
      Cluster::ShowNodes.new(info, cluster.counts, verbose: verbose).show(STDOUT)

    when /^info$/i
      field = (args.empty? || args[0].empty?) ? "v,cnt,m,d" : args[0]
      Cluster::ShowInfos.new(cluster).show(STDOUT, field: field)

    when /^watch$/i
      sec1 = args.shift { 1 }.to_i.seconds
      sec2 = args.shift { 3 }.to_i.seconds
      Watch.watch(cluster, crt: !nocrt, watch_interval: sec1, nodes_interval: sec2)

    when /^create$/i
      die "create expects <node...> # ex. 'create 192.168.0.1:7001 192.168.0.2:7002'" if args.empty?
      create = Create.new(args, pass: pass, masters: masters)
      if nop
        create.dryrun(STDOUT)
      else
        create.execute
      end

    when /^addslots$/i
      slot = Slot.parse(args.join(","))
      die "addslots expects <slot range> # ex. 'addslot 0-16383'" if slot.empty?
      puts "ADDSLOTS #{slot.to_s} (total: #{slot.size} slots)"
      puts redis.addslots(slot.slots)
      
    when /^meet$/i
      host = args.shift { die "meet expects <base node> # ex. 'meet 127.0.0.1:7001'" }
      addr = Addr.parse(host)
      puts "MEET #{addr.host} #{addr.port}"
      puts redis.meet(addr.host, addr.port.to_s)
      
    when /^join$/i
      addrs = args.map{|host| Addr.parse(host)}
      base = addrs.first { die "join expects <nodes> # ex. 'join 127.0.0.1:7001 127.0.0.1:7002 ...'" }
      puts "JOIN #{addrs.size} nodes to #{base}"
      cons = addrs.map{|a|
        redis_for(a).tap(&.meet(base.host, base.port.to_s))
      }
      while cons.map{|r| signature_for(r)}.uniq.size > 1
        sleep 1
      end
      puts "OK"
      
    when /^replicate$/i
      name = args.shift { die "replicate expects <master>" }
      info = ClusterInfo.parse(redis.nodes)
      node = info.find_node_by!(name)
      puts "REPLICATE #{node.addr}"
      puts redis.replicate(node.sha1)

    when /^failover$/i
      puts redis.failover

    when /^takeover$/i
      puts redis.takeover

    when /^get$/i
      key = args.shift { die "get expects <key>" }
      val = cluster.get(key)
      puts val.nil? ? "(nil)" : val.inspect

    when /^set$/i
      key = args.shift { die "set expects <key> <val>" }
      val = args.shift { die "get expects <key> <val>" }
      cluster.set(key, val)

    when /^import$/i
      name = args.shift { die "import expects <tsv-file>" }
      file = safe{ File.open(name) }
      step = Cluster::StepImport.new(cluster)
      step.import(file, delimiter: "\t", progress: true, count: 1000)
      
    when /^advise$/i
      replica = Advise::BetterReplication.new(cluster.cluster_info, cluster.counts)
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
    @redis ||= Redis.new(host: host, port: port, password: pass)
  end

  private def redis_for(addr : Addr)
    Redis.new(host: addr.host, port: addr.port, password: pass)
  end

  private def cluster
    @cluster ||= Redis::Cluster.new("#{host}:#{port}", pass)
  end

  private def signature_for(redis)
    ClusterInfo.parse(redis.nodes).nodes.map(&.signature).sort.join("|")
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
      STDERR.puts "try `-a` option: 'rcm -a XXX'"
    end
  end
end

Rcm::Main.new.run
