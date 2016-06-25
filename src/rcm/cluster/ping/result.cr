module Rcm::Cluster::Ping
  record Result,
    node : NodeInfo,
    time : Time,
    count : Int64
end
