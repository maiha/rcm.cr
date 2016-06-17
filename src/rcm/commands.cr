module Rcm::Commands
  abstract def redis(key : String) : Redis

  def get(key)
    redis(key).get(key)
  end
  
  def set(key, val)
    redis(key).set(key, val)
  end
end
