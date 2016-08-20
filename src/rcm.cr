require "redis-cluster"
require "./ext/**"
require "./lib/*"
require "./rcm/**"

module Rcm
  include Redis::Cluster
end
