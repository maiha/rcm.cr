module Rcm
  record Addr,
    host : String,
    port : Int32 do

    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 6379

    delegate size, to: to_s

    def self.parse(str : String)
      host, port = str.split(":", 2)
      host = "127.0.0.1" if host.to_s.empty? # sometimes Redis returns ":7001" for addr part
      raise "port not found: `#{str}`" if port.to_s.empty?
      begin
        port = port.to_i
      rescue err : ArgumentError
        raise "port not converted: #{err} from `#{str}`"
      end

      new(host, port.as(Int32))
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
