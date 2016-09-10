module Rcm::Watch::Show
  module Core
    def clear
    end

    def refresh
    end

    abstract def head(msg : String) : Nil
    abstract def tail(msg : String) : Nil
    abstract def print(name : String, msg : String) : Nil
  end

  class IO
    include Core

    def initialize(@io : ::IO = STDOUT)
    end

    def head(msg : String)
      @io.puts msg
    end

    def tail(msg : String)
      @io.puts msg
    end

    def print(key : String, val : String)
      @io.puts "#{key} #{val}"
    end

    def refresh
      @io.flush
    end
  end

  class Crt
    include Core
    @lines : Array(Tuple(String, String))

    getter crt
    
    def initialize(@crt : ::Crt::Window = ::Crt::Window.new)
      @lines = [] of Tuple(String, String)
    end

    def clear
      @crt.clear
    end
    
    def head(msg)
      msg = "%-#{@crt.col}s" % msg
      @crt.print(0, 0, msg)
    end

    def print(name : String, body : String)
      @lines << {name, body}
    end

    def tail(msg)
      @crt.print(@crt.maxy-1,0, msg)
    end

    def refresh
      draw_lines
      @crt.refresh
      @crt.move(0, 0)
      @lines = [] of Tuple(String, String)
    end

    private def draw_lines
      key_size = @lines.map{|(k,v)| k.size}.max
      delimiter = " "
      val_size = [@crt.col - key_size - delimiter.size, 0].max
      
      @lines.each_with_index do |(k,v), i|
        val = substr_from_right(v, val_size)
        msg = "%-#{key_size}s%s%s" % [k, delimiter, val]
        @crt.print(i+1, 0, msg)
      end
    end

    private def substr_from_right(str, len)
      if str.size <= len
        str
      else
        offset = str.size - len
        str[offset .. -1]
      end
    end
  end
end
