module Periodical
  class Logger
    def initialize(@interval : Time::Span, @io : IO = STDOUT)
      @started_at = @reported_at = Time.now
    end

    def puts(msg)
      now = Time.now
      return if now < @reported_at + @interval
      @io.puts msg
      @io.flush
      @reported_at = now
    end

    def took
      Time.now - @started_at
    end
  end
end
