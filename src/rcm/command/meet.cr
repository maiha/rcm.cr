module Rcm::Command
  record Meet,
    addr : Addr,
    dst : Addr,
    pass : String? = nil do
    include Rcm::Command

    private def opts
      "meet '#{dst}'"
    end
  end
end
