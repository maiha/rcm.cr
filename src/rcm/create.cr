class Rcm::Create
  @commands : Array(Rcm::Command) = [] of Rcm::Command
  @addrs    : Array(Addr) = [] of Addr
  @masters  : Array(Addr) = [] of Addr
  @leader   : Addr

  property commands

  def initialize(nodes : Array(String), @pass : String? = nil)
    raise "nodes not found" if nodes.empty?
    @addrs = nodes.map{|s| Addr.parse(s)}
    @leader = @addrs.first
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
    @addrs.each do |addr|
      next if @masters.any?{|a| a.host == addr.host}
      @masters << addr
    end
  end

  private def build_meets
    @addrs.each_with_index do |addr, i|
      next if addr == @leader
      commands << Rcm::Command::Meet.new(addr, @leader, @pass)
    end
  end

  private def build_addslots
    size = (Slot::SIZE.to_f / @masters.size).ceil.to_i # 16384 / 3 = 5463
    @masters.each_with_index do |addr, i|
      head = size * i
      tail = [size * (i + 1) - 1, Slot::LAST].min
      commands << Rcm::Command::Addslots.new(addr, "#{head}-#{tail}", @pass)
    end
  end

  private def build_replicates
    unbound = @addrs - @masters
    unbound.each_with_index do |addr, i|
      margin = width_for(addr) - depth_for(addr)
      master = @masters[(@masters.size + margin) % @masters.size]
      commands << Rcm::Command::Replicate.new(addr, master, @pass)
    end
  end

  private def width_for(addr)
    width = 0
    @masters.each do |m|
      if m.host == addr.host
        return width
      else
        width += 1
      end
    end
    raise "[BUG] #{self.class}#width_for"
  end

  private def depth_for(addr)
    depth = 0
    @addrs.each do |a|
      if a.host == addr.host
        if a.port == addr.port
          return depth
        else
          depth += 1
        end
      end
    end
    raise "[BUG] #{self.class}#depth_for"
  end

  private def each
    commands.each do |cmd|
      yield(cmd)
    end
  end
end
