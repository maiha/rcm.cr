module Rcm::Advise
  record Replicate,
    master : NodeInfo,
    slave : NodeInfo do

    def cmd
      "rcm #{slave.addr.connection_string} REPLICATE #{master.addr}"
    end

    def to_s(io : IO)
      io << cmd
    end
  end
end

require "./advise/*"
