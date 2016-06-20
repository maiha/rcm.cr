module Rcm
  record Addr,
    host : String,
    port : Int32 do

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
  end
end
