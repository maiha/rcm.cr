require "redis-cluster"
require "./lib/*"
require "./rcm/**"

module Rcm
  include Redis::Cluster
end
