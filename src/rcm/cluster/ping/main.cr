module Rcm::Cluster::Ping
  def self.ping(client, interval : Time::Span = 1.second)
    Main.new(client, interval).run
  end

  class Main
    delegate nodes, to: info

    MAX_VAL_SIZE = 256          # max terminal colum size we expect
    
    @watchers : Array(Watcher)
    @ch : Channel::Unbuffered(Result)
    @noded_counts : Hash(NodeInfo, Array(Int64))

    def initialize(@client : Client, @interval : Time::Span)
      @ch  = Channel(Result).new
      @watchers = nodes.map{|n| Watcher.new(n, ->(){@client.new_redis(n)}, @ch)}
      @noded_counts = Hash(NodeInfo, Array(Int64)).new
      @crt = Crt::Window.new
      @show = Show::Crt.new(@crt)
      @time_body = MemoryIO.new
    end

    def run
      @watchers.each(&.start(@interval))
      spawn { update }
      spawn { render }
      STDIN.gets
    end

    private def update
      loop {
        result = @ch.receive
        counts_for(result.node) << result.count
        sleep 0
      }
    end

    private def render
      schedule_each(@interval) {
        shrink_counts
        shrink_time_body

        @show.clear
        @show.head(Time.now.to_s)
        @show.print("", build_time_body)
        nodes.each do |node|
          key = build_key_for(node)
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

    private def info
      @client.cluster_info
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
