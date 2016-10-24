require "../rcm"
require "../options"
require "colorize"

class Rcm::Main
  include Options
  include Rcm::Cluster::NodesHelper

  VERSION = "0.6.3"

  option uri   : String?, "-u <uri>", "Give host,port,pass at once by 'pass@host:port'", nil
  option host  : String?, "-h <hostname>", "Server hostname (override uri)", nil
  option port  : Int32? , "-p <port>", "Server port (override uri)", nil
  option sock  : String?, "-s <socket>", "Server socket (overrides hostname and port)", nil
  option pass  : String?, "-a <password>", "Password for authed node", nil
  option yes   : Bool, "--yes", "Accept advise automatically", false
  option nop   : Bool, "-n", "Print the commands that would be executed", false
  option nocrt : Bool, "--nocrt", "Use STDIO rather than experimental CRT", false
  option masters : Int32? , "--masters <num>", "[create only] Master num", nil
  option timeout : Int32, "-t sec", "Timeout sec for operation", 60
  option verbose : Bool, "-v", "Enable verbose output", false
  option version : Bool, "--version", "Print the version and exit", false
  option help  : Bool  , "--help", "Output this help and exit", false
  
  usage <<-EOF
    rcm version #{VERSION}

    Usage: rcm <commands>

    Options:

    Commands:
      status              Print cluster status
      schema              Print cluster schema
      nodes (file)        Print nodes info from file or server
      info <field>        Print given field from INFO for all nodes
      watch <sec1> <sec2> Monitor counts of cluster nodes
      create <addr1> ...  Create cluster
      join <addr1> ...    Waiting for the cluster to join
      addslots <slots>    Add slots to the node
      meet <master>       Join the cluster on <master>
      replicate <master>  Configure node as replica of the <master>
      fail                Become slave gracefully (master only)
      failback            Become master gracefully (slave only)
      failover            Become master with agreement (slave only)
      takeover            Become master without agreement (slave only)
      forget <node>       Remove the node from cluster
      slot <key1> <key2>  Print keyslot values of given keys
      import <tsv file>   Test data import from tsv file
      advise (--yes)      Print advises. Execute them when --yes given
      httpd <bind>        Start http rest api
      (default)           Otherwise, delgate to redis as is

    Example:
      rcm nodes
      rcm info redis_version
      rcm create 192.168.0.1:7001 192.168.0.2:7001 ... --masters 3
      rcm addslots 0-100            # or "0,1,2", "10000-"
      rcm meet 127.0.0.1:7001       # or shortly "meet :7001"
      rcm replicate 127.0.0.1:7001  # or shortly "replicate :7001"
      rcm httpd localhost:8080      # or shortly "httpd :8080"
    EOF

  def run
    args                        # kick parse!
    quit(usage) if help
    quit("rcm #{VERSION}") if version

    op = args.shift { die "command not found!" }

    case op
    when /^myid$/i
      puts redis.myid

    when /^role$/i
      puts info_replication["role"]?

    when /^replication\.json$/i
      puts info_replication.to_json

    when /^status$/i
      Cluster::ShowStatus.new(cluster.cluster_info, cluster.counts, verbose: verbose).show(STDOUT)

    when /^schema$/i
      Cluster::ShowSchema.new(cluster.cluster_info).show(STDOUT)

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
      die "create expects --masters > 0" if masters.try(&.< 0)
      create = Create.new(args, pass: boot.pass, masters: masters)
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
      base = args.shift { die "meet expects <base node> # ex. 'meet 127.0.0.1:7001'" }
      addr = Addr.parse(base)
      puts "MEET #{addr.host} #{addr.port}"
      puts redis.meet(addr.host, addr.port.to_s)
      
    when /^join$/i
      addrs = args.map{|s| Addr.parse(s)}
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

    when /^fail$/i, /^become_slave$/i
      do_fail

    when /^failback$/i
      do_failback

    when /^forget$/i
      name = args.shift { die "replicate expects <node>" }
      info = ClusterInfo.parse(redis.nodes)
      sha1 = info.find_node_by!(name).sha1
      puts "FORGET #{sha1}"
      info.nodes.each do |n|
        next if n.sha1 == sha1
        cluster.redis(n).string_command(["CLUSTER", "FORGET", sha1])
      end

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

    when "httpd"
      listen = args.shift { die "httpd expects <(auth@)host:port>" }
      server = Httpd::Server.new(client, Bootstrap.parse(listen))
      server.start
      
    when "slot"
      args.each do |key|
        slot = Redis::Cluster::Slot.slot(key)
        if verbose
          puts "#{key}\t#{slot}"
        else
          puts slot
        end
      end

    else
      # otherwise, delegate to redis as commands
      cmd = [op] + args
      val = client.command(cmd)
      puts val.nil? ? "(nil)" : val.inspect
    end
  rescue err
    STDERR.puts err.to_s.colorize(:red)
    suggest_for_error(err)
    exit 1
  ensure
    redis.close if @redis
  end

  @boot : Bootstrap?
  private def boot
    (@boot ||= Bootstrap.parse(uri.to_s).copy(host: host, port: port, sock: sock, pass: pass)).not_nil!
  end

  @redis : Redis?
  private def redis
    (@redis ||= boot.redis).not_nil!
  end

  private def redis_for(addr : Addr)
    Redis.new(host: addr.host, port: addr.port, password: boot.pass)
  end

  # Hybrid client for standard or clustered
  private def client
    @client ||= ::Redis::Client.new(boot)
  end

  private def cluster : ::Redis::Cluster::Client
    @cluster ||= Redis::Cluster.new(boot)
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

  # aka. become_slave
  private def do_fail
    info = ClusterInfo.parse(redis.nodes)
    master = info.find_node_by!(redis.myid) # use myid for unixsock

    started_at = Time.now
    timeout_at = started_at + timeout.seconds

    if master.master?
      # 1. send FAILOVER command to its slave
      slave = sort_slaves(info.slaves_of(master)).first {
        STDERR.puts "no slaves for #{master.addr}".colorize.yellow
        exit 0
      }
      cluster.redis(slave).failover # => "OK"

      # 2. wait to become slave (timeout=30)
      logger = Periodical::Logger.new(interval: 3.seconds)
      wait_for_condition(timeout_at, interval: 1.second) {
        role = info_replication["role"]?
        logger.puts "  #{Time.now} role=#{role}"
        role == "slave"
      }
      puts "slave: OK (%.1f sec)" % [logger.took.total_seconds]
    else
      # when the node is already slave, just print warning
      STDERR.puts "slave: #{master.addr} is already slave".colorize.yellow
    end

    # 3. wait for replication (master is up)
    logger = Periodical::Logger.new(interval: 3.seconds)
    wait_for_condition(timeout_at, interval: 1.second) {
      link = info_replication["master_link_status"]?
      logger.puts "  #{Time.now} master link=#{link}"
      link == "up"
    }
    puts "master link: OK (%.1f sec)" % [logger.took.total_seconds]
  end

  private def do_failback
    started_at = Time.now
    timeout_at = started_at + timeout.seconds

    if info_replication["role"]? == "slave"
      # 1. send FAILOVER to me
      res = redis.failover
      raise res unless res == "OK"

      # 2. wait to become master (timeout=30)
      logger = Periodical::Logger.new(interval: 3.seconds)
      wait_for_condition(timeout_at, interval: 1.second) {
        role = info_replication["role"]?
        logger.puts "  #{Time.now} role=#{role}"
        role == "master"
      }
      puts "master: OK (%.1f sec)" % [logger.took.total_seconds]
    else
      # when the node is already master, just print warning
      STDERR.puts "master: already master".colorize.yellow
    end

    # 3. wait all slaves to be "state=online"
    logger = Periodical::Logger.new(interval: 3.seconds)
    wait_for_condition(timeout_at, interval: 1.second) {
      states = slave_states
      logger.puts "  debug: #{Time.now} states=#{states.inspect}"
      (states.empty? || states == ["online"])
    }
    puts "slave state: OK (%.1f sec)" % [logger.took.total_seconds]
  end

  private def info_replication
    redis.info("replication")
  end

  private def slave_states : Array(String)
    states = Set(String).new

    info_replication.each do |key, val|
      # "slave0": "ip=192.168.0.2,port=6002,state=wait_bgsave,offset=0,lag=0",
      # "slave1": "ip=192.168.0.3,port=6003,state=wait_bgsave,offset=0,lag=0",
      next if key !~ /^slave/
      case val
      when /state=(.*?),/
        states << $1
      end
    end

    return states.to_a
  end
end

Rcm::Main.new.run
