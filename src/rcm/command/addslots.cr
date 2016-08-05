module Rcm::Command
  record Addslots,
    addr : Addr,
    slot : String,
    pass : String? = nil do
    include Rcm::Command

    private def opts
      "addslots '#{slot}'"
    end
  end
end
