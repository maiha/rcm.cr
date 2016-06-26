module Rcm::Cluster::Ping
  record Result,
    node : NodeInfo,
    count : Int64
end
