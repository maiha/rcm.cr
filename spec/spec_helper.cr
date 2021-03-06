require "spec"
require "../src/rcm"

def fixtures(name)
  File.read("#{__DIR__}/fixtures/#{name}")
end

# derived from "src/redis/commands.cr"
def redis_info(bulk)
  results = Hash(String, String).new
  bulk.split("\n").each do |line|
    next if line.empty? || line[0] == '#'
    key, val = line.split(":")
    results[key] = val
  end
  results
end

def load_cluster_info(name)
  Rcm::ClusterInfo.parse(fixtures(name))
end

def node_mark(node : Rcm::NodeInfo)
  if node.serving?
    "M"
  elsif node.master?
    "-"
  else
    "S"
  end
end

def remove_ansi_color(str : String)
  str.gsub(/\x1B\[[0-9;]*[mK]/, "")
end
