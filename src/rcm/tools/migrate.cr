class Rcm::Tools::Migrate
  record Command,
    addr : Redis::Cluster::Addr, key : String, db : Int32, timeout : Int32,
    copy : Bool, replace : Bool, keys : Array(String) do

    delegate host, port, to: addr

    def to_s(io : IO)
      io << query.join(" ")
    end

    def inspect(io : IO)
      io << to_s.gsub(/KEYS (.+)$/) {
        keys = $1.split(/\s+/)
        head = keys[0,3].join(" ")
        tail = keys.size > 3 ? " ..." : ""
        "(%d) %s%s" % [keys.size, head, tail]
      }
    end

    def query
      q = ["MIGRATE", host, port, key, db, timeout].map(&.to_s)
      q << "COPY" if copy
      q << "REPLACE" if replace
      if keys.any?
        q << "KEYS"
        q += keys
      end
      return q
    end
  end

  property item_count : Int32
  property exec_count : Int32
  
  def initialize(@src : Redis, @dst : Redis::Cluster::Client, @copy : Bool, @replace : Bool, @count : Int32 = 10000, @timeout_ms : Int32 = 5000, @log_interval : Time::Span = 3.seconds)
    @item_count = 0
    @exec_count = 0
  end

  def dryrun(io : IO)
    each_step do |cmds|
      cmds.each do |cmd|
        io.puts cmd.inspect
      end
    end
    io.puts "# total: %d items, %d execs" % [item_count, exec_count]
  end

  def execute
    counter = Periodical.counter(interval: @log_interval, total_func: ->{ @src.count.to_i32 })
    each_step do |cmds|
      cmds.each do |cmd|
        @src.string_command(cmd.query)
      end
      counter.report(@item_count)
    end
    counter.done
    puts "# total: %d items, %d execs" % [item_count, exec_count]
  end

  protected def each_step
    @item_count = 0
    @exec_count = 0

    @src.each_keys(count: @count) do |keys|
      maps = Hash(Redis::Cluster::Addr, Array(String)).new

      keys.each do |key|
        addr = @dst.addr(key)
        maps[addr] ||= [] of String
        maps[addr] << key
      end

      # for stats
      maps.each do |addr, keys|
        @item_count += keys.size
        @exec_count += 1
      end

      cmds = maps.keys.sort_by(&.to_s).map{|addr|
        keys = maps[addr]
        Command.new(addr, "", 0, @timeout_ms, @copy, @replace, keys)
      }
      yield cmds
    end
  end
end
