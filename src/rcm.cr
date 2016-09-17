# Crystal
require "http"

# Dependencies
require "redis-cluster"
require "kemal"
require "crt"

# Project
require "./ext/**"
require "./lib/*"
require "./rcm/**"

module Rcm
  include Redis::Cluster
end
