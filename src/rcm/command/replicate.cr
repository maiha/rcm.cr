module Rcm::Command
  record Replicate,
    addr : Addr,
    dst : Addr do
    include Rcm::Command

    private def opts
      "replicate '#{dst}'"
    end
  end
end
