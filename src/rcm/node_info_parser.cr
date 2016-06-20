struct Rcm::NodeInfo
  def self.parse(line : String) : Rcm::NodeInfo
    # 2afb4da9d68942a32676ca19e77492c4ba921d0f 127.0.0.1:7001 myself,master - 0 0 1 connected 0-5460
    # 56f1954c1fa7b63fb631a872480dbf0a93bc8a9a 127.0.0.1:7004 slave 2afb4da9d68942a32676ca19e77492c4ba921d0f 0 1466089461937 1 connected
    ary = line.split
    argc = 0
    shift = ->(){
      if ary[0]?
        argc += 1
        ary.shift
      else
        raise "node format error: expected data[#{argc}], but missing. `#{line}'"
      end
    }
           
    sha1   = shift.call
    addr   = shift.call
    flags  = shift.call
    master = shift.call.delete("-")
    sent   = shift.call
    recv   = shift.call
    epoch  = shift.call
    status = shift.call
    slot   = ary.shift { "" }
    
    host, port = addr.split(":", 2)
    host = "127.0.0.1" if host.to_s.empty? # sometimes Redis returns ":7001" for addr part
    raise "port not found: `#{line}`" if port.to_s.empty?
    begin
      port = port.to_i
    rescue err : ArgumentError
      raise "port not converted: #{err} from `#{line}`"
    end
    port = port.as(Int32)
    
    return Rcm::NodeInfo.new(sha1: sha1, host: host, port: port, flags: flags, master: master, sent: sent.to_i64, recv: recv.to_i64, epoch: epoch.to_i64, status: status, slot: slot)
  end
end

def Array(Rcm::NodeInfo).parse(buf : String) : Array(Rcm::NodeInfo)
  nodes = [] of Rcm::NodeInfo
  buf.each_line do |line|
    nodes << Rcm::NodeInfo.parse(line.chomp)
  end
  return nodes.sort_by(&.addr)
end
