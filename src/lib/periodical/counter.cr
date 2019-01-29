module Periodical
  def self.counter(interval : Time::Span, total_func : -> Int32)
    total = total_func.call
    if total > 0
      return Counter.new(interval, total) 
    else
      return Nop.new
    end
  end

  def self.counter(enable : Bool, interval : Time::Span, total_func : -> Int32)
    if enable
      return counter(interval, total_func)
    else
      return Nop.new
    end
  end

  class Nop
    def report(i : Int32)
    end

    def done
    end
  end

  class Counter
    def initialize(@interval : Time::Span, @total : Int32)
      @started_at = @reported_at = Pretty.now
      @report_count = 0
      @last_count = 0
      raise "#{self.class} expects @total > 0, bot got #{@total}" unless @total > 0
    end

    def report(cnt : Int32)
      now = Pretty.now
      return if now < @reported_at + @interval
      pcent = [cnt * 100.0 / @total, 100.0].min
      time = now.to_s("%H:%M:%S")
      qps = qps_string(cnt - @last_count, now - @reported_at)

      STDERR.puts "%s [%03.1f%%] %d/%d (%s)" % [time, pcent, cnt, @total, qps]
      STDERR.flush
      @last_count = cnt
      @reported_at = now
      @report_count += 1
    end

    def done
      now  = Pretty.now
      took = now - @started_at
      qps  = qps_string(@total, took)
      sec  = took.total_seconds
      time = now.to_s("%H:%M:%S")
      STDERR.puts "%s done %d in %.1f sec (%s)" % [time, @total, sec, qps]
    end

    private def qps_string(count, took : Time::Span)
      qps = count*1000.0 / took.total_milliseconds
      return "%.1f qps" % qps
    rescue
      return "--- qps"
    end
  end
end
