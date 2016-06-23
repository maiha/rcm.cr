module Rcm::Advise
  record Replicate,
    master : NodeInfo,
    slave : NodeInfo do

    def to_s(io : IO)
      io << "rcm #{slave.addr.connection_string} REPLICATE #{master.addr}"
    end
  end
end

require "./advise/*"
