module Periodical
  class Logger
    def initialize(@interval : Time::Span, @io : IO = STDOUT)
      @started_at = @reported_at = Pretty.now
    end

    def puts(msg)
      now = Pretty.now
      return if now < @reported_at + @interval
      @io.puts msg
      @io.flush
      @reported_at = now
    end

    def took
      Pretty.now - @started_at
    end
  end
end
