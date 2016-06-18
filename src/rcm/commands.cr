module Rcm::Commands
  abstract def redis(key : String) : Redis

  def get(key)
    redis(key).get(key)
  end
  
  def set(key, val)
    redis(key).set(key, val)
  end

  def counts
    nodes.reduce(Hash(NodeInfo, Int64).new) do |h, n|
      h[n] = redis(n).count
      h
    end
  end

  def info(field : String)
    nodes.reduce(Hash(NodeInfo, Array(InfoExtractor::Value)).new) do |hash, node|
      info = InfoExtractor.new(redis(node).info)
      keys = field.split(",").map(&.strip)
      hash[node] = keys.map{|k| info.extract(k)}
      hash
    end
  end
end
