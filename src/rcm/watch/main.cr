module Rcm::Watch
  def self.watch(client, watch_interval : Time::Span = 1.second, nodes_interval : Time::Span = 3.seconds, crt : Bool = true)
    Main.new(client, watch_interval, nodes_interval, crt).run
  end

  class Main
    delegate nodes, to: @info

    MAX_VAL_SIZE = 256          # max terminal colum size we expect

    alias Nodes = String
    
    @count_ch       : Channel::Unbuffered(Result)
    @nodes_ch       : Channel::Unbuffered(Nodes)
    @count_watchers : Array(Watcher(Result))
    @nodes_watcher  : Watcher(Nodes)
    @noded_counts   : Hash(NodeInfo, Array(Int64))

    def initialize(@client : Client, @watch_interval : Time::Span, @nodes_interval : Time::Span, crt : Bool)
      @info           = @client.cluster_info
      @count_ch       = Channel(Result).new
      @nodes_ch       = Channel(Nodes).new
      @count_watchers = build_watch_watchers
      @nodes_watcher  = build_nodes_watcher
      @noded_counts   = Hash(NodeInfo, Array(Int64)).new
      @show           = crt ? Show::Crt.new : Show::IO.new
      @time_body      = MemoryIO.new
    end

    def run
      @count_watchers.each(&.start(@watch_interval))     
      @nodes_watcher.start(@nodes_interval)
      spawn { observe_channels }
      spawn { render }
      STDIN.gets
    end

    private def build_nodes_watcher
      Watcher(Nodes).new(@nodes_ch, new_redis_proc(nodes[0]),
        ->(redis : Redis) { redis.nodes },
        ->(e : Exception) { "" })
    end

    private def build_watch_watchers
      nodes.map{|n|
        Watcher(Result).new(@count_ch, new_redis_proc(n),
          ->(redis : Redis) { Result.new(n, redis.count!) },
          ->(e : Exception) { Result.new(n, -1_i64) })
      }
    end

    private def new_redis_proc(node : NodeInfo)
      ->() { @client.new_redis(node) }
    end

    private def observe_channels
      receives = [@count_ch, @nodes_ch].map(&.receive_op)
      loop {
        index, value = Channel.select(receives)
        case index
        when 0
          update_count(value.as(Result))
        when 1
          update_nodes(value.as(Nodes))
        else
          raise "[BUG] observe_channels got unexpected index(#{index})"
        end
        # sleep 0 # Comment out anyway. I don't know why this is bad
      }
    end

    private def update_nodes(nodes : Nodes)
      unless nodes.empty?
        @info = ClusterInfo.parse(nodes)
      end
    end

    private def update_count(result : Result)
      counts_for(result.node) << result.count
    end

    private def render
      schedule_each(@watch_interval) {
        shrink_counts
        shrink_time_body

        @show.clear
        @show.head(Time.now.to_s)
        @show.print("", build_time_body)
        @info.each_nodes do |node|
#          key = build_key_for(node)
          key = build_typed_key(node)
          val = build_body_for(node)
          @show.print(key, val)
        end
        @show.refresh
      }
    end

    private def counts_for(node : NodeInfo)
      @noded_counts[node] ||= [] of Int64
    end

    private def build_key_for(node)
      a = counts_for(node)
      c = a.last { -1 }
      "#{node.addr}(#{c})"
    end

    private def build_typed_key(node)
      c = counts_for(node).last { -1 }
      if node.serving?
        prefix = "[%-11s] " % node.slot
        "#{prefix}#{node.addr}(#{c})"
      elsif node.master?
        prefix = " ( no slots ) "
        "#{prefix}#{node.addr}(#{c})"
      else
        prefix = "    +slave    "
        "#{prefix}#{node.addr}(#{c})"
      end
    end

    private def build_body_for(node)
      ary = counts_for(node)
      last_valid = nil
      ary.map{|current|
        if current == -1
          "E"
        else
          prev = last_valid
          last_valid = current
          case prev
          when Int64
            if current > prev
              "+"
            elsif current < prev
              "-"
            else
              "."
            end
          else
            "."
          end
        end
      }.join
    end

    # shrink count buffer to MAX_VAL_SIZE
    private def shrink_counts
      return if @noded_counts.empty?
      return if @noded_counts.first[1].size < MAX_VAL_SIZE * 2
      @noded_counts.each do |(k,a)|
        a[0, MAX_VAL_SIZE] = [] of Int64
      end
    end

    # shrink time_body to MAX_VAL_SIZE
    private def shrink_time_body
      if @time_body.size > MAX_VAL_SIZE * 2
        buf = (@time_body.to_s)[MAX_VAL_SIZE .. -1]
        @time_body = MemoryIO.new
        @time_body << buf
      end
    end

    private def build_time_body
      # |14:53
      now = Time.now
      case now.second
      when 0
        @time_body << "|"
      when 1..2
        @time_body << now.to_s("%H")[now.second - 1, 1]
      when 3
        @time_body << ":"
      when 4..5
        @time_body << now.to_s("%M")[now.second - 4, 1]
      else
        @time_body << " "
      end
      @time_body.to_s
    end
  end
end
