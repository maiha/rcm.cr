require "redis"

class Redis::Error
  def to_json(io : IO)
    message.to_json(io)
  end
end
