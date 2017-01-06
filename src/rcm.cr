# Crystal
require "http"

# Dependencies
require "redis-cluster"
require "kemal"
require "kemal-basic-auth"
require "crt"
require "app"

# Project
require "./ext/**"
require "./lib/*"
require "./rcm/**"

module Rcm
  include Redis::Cluster
end
