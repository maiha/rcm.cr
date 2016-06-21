require "logger"

class BufferedLogger < Logger
  def initialize(@color : Bool = true, @prefix : String = "")
    @buffer = MemoryIO.new
    @counts = Hash(Logger::Severity, Int32).new { 0 }
    super(@buffer)

    @formatter = Formatter.new do |severity, datetime, progname, message, io|
      message = colorize(severity, message) if @color
      io << @prefix if @prefix.size > 0
      io << message
    end
  end

  # return true when no logs contain any warns, errors and fatals
  def ok?
    return false if wa?
    return false if ng?
    return true
  end

  def wa?
    [Severity::WARN].any?{|s| @counts[s] > 0}
  end

  def ng?
    [Severity::ERROR, Severity::FATAL].any?{|s| @counts[s] > 0}
  end

  private def colorize(severity, message)
    case severity.to_s
    when Severity::WARN.to_s
      message.colorize.yellow
    when Severity::INFO.to_s
      message.colorize.green
    when Severity::ERROR.to_s, Severity::FATAL.to_s
      message.colorize.red
    else
      "#{severity.inspect}: #{message}"
    end
  end
  
  def log(severity, message, progname = nil)
    @counts[severity] += 1
    super
  end
  
  def flush(io : IO)
    @buffer.rewind
    @buffer.each_line do |line|
      io << line
    end
  end
end
