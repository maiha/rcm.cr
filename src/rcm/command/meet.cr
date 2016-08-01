module Rcm::Command
  record Meet,
    addr : Addr,
    dst : Addr do
    include Rcm::Command

    private def opts
      "meet '#{dst}'"
    end
  end
end
