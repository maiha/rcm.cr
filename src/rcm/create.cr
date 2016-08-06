class Rcm::Create
  @commands   : Array(Rcm::Executable)   = [] of Rcm::Executable
  @addrs      : Array(Addr)              = [] of Addr
  @masters    : Array(Addr)              = [] of Addr
  @slaves     : Hash(Addr, Array(Addr))  = Hash(Addr, Array(Addr)).new
  @degree     : Hash(Set(String), Int32) = Hash(Set(String), Int32).new
  @leader     : Addr
  @master_num : Int32

  property commands

  def initialize(nodes : Array(String), @pass : String? = nil, @wait : Float64 = 1.0, masters : Int32? = nil, @debug : Bool = false)
    raise "nodes not found" if nodes.empty?
    @addrs = nodes.map{|s| Addr.parse(s)}
    @leader = @addrs.first
    @master_num = calculate_master_num(masters)
    build_masters
    build_meets
    build_addslots
    build_replicates
  end

  def dryrun(io : IO)
    each(&.dryrun(io))
  end

  def execute
    cmd = commands.map(&.command).join(" && ")
    system(cmd)
  end

  private def build_masters
    if @master_num
      # 1. fill masters with condition that fetches 1 node from 1 host
      @addrs.each do |addr|
        return if @masters.size == @master_num
        next if @masters.any?{|a| a.host == addr.host}
        @masters << addr
      end

      # 2. fill masters from all hosts
      (@addrs - @masters).each do |addr|
        return if @masters.size == @master_num
        @masters << addr
      end
    else
      # Give up because there is no hints for masters and replicas
      raise "[BUG] @master_num must exists in our logic"
    end
  end

  private def build_meets
    @addrs.each_with_index do |addr, i|
      next if addr == @leader
      commands << Rcm::Command::Meet.new(addr, @leader, @pass)
    end
  end

  private def build_addslots
    return if @masters.none?
    
    size = (Slot::SIZE.to_f / @masters.size).ceil.to_i # 16384 / 3 = 5463
    @masters.each_with_index do |addr, i|
      head = size * i
      tail = [size * (i + 1) - 1, Slot::LAST].min
      commands << Rcm::Command::Addslots.new(addr, "#{head}-#{tail}", @pass)
    end
  end

  private def build_replicates
    return if @masters.none?

    unbound = @addrs - @masters
    commands << Rcm::Command::Wait.new(@wait) if unbound.any? && @wait > 0
    
    unbound.each_with_index do |slave, i|
      master = find_master_for(slave)
      replicate(slave, master)
    end
  end

  private def slaves_of(master : Addr)
    @slaves[master] ||= Array(Addr).new
  end

  private def degree_of(master : Addr, slave : Addr)
    @degree[Set{master.host, slave.host }]? || 0
  end

  private def replicate(slave, master)
    commands << Rcm::Command::Replicate.new(slave, master, @pass)
    slaves_of(master) << slave
    @degree[Set{master.host, slave.host }] ||= 0
    @degree[Set{master.host, slave.host }] += 1
  end

  private def calculate_master_num(masters) : Int32
    # Use it when explicitly given
    return masters if masters

    # Use the number of hosts for default
    hosts = @addrs.map(&.host).uniq
    if hosts.size > 1
      return hosts.size
    else
      # Treat all nodes as master when all nodes are in 1 host
      return @addrs.size
    end
  end

  # Find a master score for the slave by following order
  private def master_score_for(slave, master)
    score = [] of Int32
    # 1. same host
    score << ((master.host == slave.host) ? 1 : 0)
    # 2. slave capacity overflow
    rf = (@addrs.size.to_f / @masters.size).ceil
    score << ((slaves_of(master).size < rf - 1) ? 0 : 1)
    # 3. host degree
    score << degree_of(master, slave)
    # 4. order of nodes
    offset = @masters.index(@masters.find(@masters.first.not_nil!){|m| m.host == slave.host}).not_nil!
    score << ((offset - 1 + @masters.size - @masters.index(master).not_nil!) % @masters.size)
    return score
  end

  # Find a best master for the slave about replication
  private def find_master_for(slave)
    show_replicate_plan_for(slave) if @debug
    @masters.sort_by{|m| master_score_for(slave, m)}.first.not_nil!
  end

  private def each
    commands.each do |cmd|
      yield(cmd)
    end
  end

  def show_replicate_plan_for(slave : Addr, io : IO = STDOUT)
    io.puts ""
    io.puts "="*60
    io.puts "find_master_for(#{slave})"
    io.puts "-"*60
    io.puts "# [slaves]"
    @slaves.keys.sort_by(&.to_s).each do |key|
      io.puts "  #{key}: #{@slaves[key].map(&.to_s)}"
    end
    io.puts "-"*60
    io.puts "# [degree]"
    @degree.keys.sort_by(&.to_a.map(&.to_s).sort.join(", ")).each do |key|
      val = @degree[key]
      next if val == 0
      sorted_key = key.to_a.map(&.to_s).sort.join(", ")
      io.puts "  (#{sorted_key}): #{val}"
    end
    io.puts "-"*60
    @masters.each do |m|
      io.puts "  #{m.to_s}: #{master_score_for(slave, m)}"
    end
    io.puts "-"*60
    master = @masters.sort_by{|m| master_score_for(slave, m)}.first.not_nil!
    io.puts "=> #{master.to_s}"
  end
end
