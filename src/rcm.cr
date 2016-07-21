require "redis"
require "crc16"
require "./macros"
require "./lib/**"
require "./ext/**"

module Rcm
  include Redis::Cluster
end

require "./rcm/**"
