module Rcm::Cluster::Ping::Show
  module Core
    abstract def clear : Nil
    abstract def head(msg : String) : Nil
    abstract def print(name : String, msg : String) : Nil
    abstract def tail(msg : String) : Nil
    abstract def refresh : Nil
  end

  class Crt
    include Core
    @lines : Array(Tuple(String, String))

    def initialize(@crt : Crt::Window)
      @lines = [] of Tuple(String, String)
    end

    def clear
      @crt.clear
      @lines = [] of Tuple(String, String)
    end
    
    def head(msg)
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
