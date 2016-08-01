module Rcm::Command
  record Addslots,
    addr : Addr,
    slot : String do
    include Rcm::Command

    private def opts
      "addslots '#{slot}'"
    end
  end
end
