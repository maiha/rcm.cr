require "redis"
require "crc16"
require "./macros"
require "./lib/**"
require "./ext/**"

module Rcm
  alias Counts = Hash(NodeInfo, Int64)
end

require "./rcm/**"
