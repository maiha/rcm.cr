module Rcm::Commands
  def nodes
    string_command(["CLUSTER", "NODES"])
  end
end
