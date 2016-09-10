# Dependencies
require "redis-cluster"
require "crt"

# Project
require "./ext/**"
require "./lib/*"
require "./rcm/**"

module Rcm
  include Redis::Cluster
end
