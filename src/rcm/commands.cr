module Rcm::Commands
  abstract def redis(key : String) : Redis

  def get(key)
    redis(key).get(key)
  end
  
  def set(key, val)
    redis(key).set(key, val)
  end

  # **Return value**: -1 when redis level error
  def counts
    nodes.reduce(Hash(NodeInfo, Int64).new) do |h, n|
      h[n] = (redis(n).count rescue -1.to_i64)
      h
    end
  end

  # **Return value**: error message is stored in value when redis level error
  def info(field : String)
    nodes.reduce(Hash(NodeInfo, Array(InfoExtractor::Value)).new) do |hash, node|
      begin
        info = InfoExtractor.new(redis(node).info)
        keys = field.split(",").map(&.strip)
        hash[node] = keys.map{|k| info.extract(k)}
      rescue err
        hash[node] = [err.to_s.as(InfoExtractor::Value)]
      end
      hash
    end
  end
end
