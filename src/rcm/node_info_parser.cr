module Rcm::NodeInfoParser
  def self.parse(line : String) : Rcm::NodeInfo
    # 2afb4da9d68942a32676ca19e77492c4ba921d0f 127.0.0.1:7001 myself,master - 0 0 1 connected 0-5460
    ary = line.split
    if ary.size < 8
      raise "node format error: expected at least 8 entries, but got #{ary.size}. `#{line}'"
    end
    sha1, addr, flags, mid, sent, recv, epoch, status, _ = line.split
    host, port = addr.split(":", 2)
    return Rcm::NodeInfo.new(sha1: sha1, host: host, port: port.to_i)
  end
end

def Array(Rcm::NodeInfoParser).parse(buf : String) : Array(Rcm::NodeInfo)
  nodes = [] of Rcm::NodeInfo
  buf.each_line do |line|
    nodes << Rcm::NodeInfoParser.parse(line.chomp)
  end
  return nodes
end
