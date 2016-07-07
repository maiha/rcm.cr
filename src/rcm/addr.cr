module Rcm
  record Addr,
    host  : String,
    port  : Int32,
    cport : Int32 do

    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 6379
    CLUSTER_PORT_INCR = 10000

    delegate size, to: to_s

    def self.parse(str : String)
      case str
      when /\A([^:]*):(\d+)@(\d+)\Z/ # busport format
        host, port, cport = $1, $2, $3
      when /\A([^:]*):(\d+)\Z/ # old format
        host, port = $1, $2
      when /:/ # port is not number
        raise "port not found: `#{str}`"
      else
        raise "unsupported format for Addr: `#{str}`"
      end

      # sometimes Redis returns ":7001" for host part
      host = "127.0.0.1" if host.to_s.empty? 
      port = port.to_i
      cport = cport ? cport.to_i : port + CLUSTER_PORT_INCR

      new(host, port, cport)
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    def to_s(io : IO)
      io << "#{host}:#{port}"
    end

    def connection_string
      String.build do |s|
        s << "-h '#{host}' "
        s << "-p #{port} "
      end.strip
    end

    def connection_string_min
      String.build do |s|
        s << "-h '#{host}' " unless host == DEFAULT_HOST
        s << "-p #{port} " unless port == DEFAULT_PORT
      end.strip
    end
  end
end
