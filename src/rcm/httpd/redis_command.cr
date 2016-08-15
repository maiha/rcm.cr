require "http/server"

module Rcm::Httpd::RedisCommand
  record CommandFound   , args : Array(String), mime : MediaType
  record CommandNotFound, name : String
  record MediaNotFound  , ext  : String
  record InvalidRequest

  def self.parse(req : HTTP::Request)
    case req.path
    when %r{\A/(.*?)\.([a-z0-9]+)\Z}
      ary = $1.split("/")
      ext = $2
    when %r{\A/(.*?)\Z}
      ary = $1.split("/")
      ext = "txt"
    else
      return InvalidRequest.new
    end

    case req.method
    when "POST", "PUT"
      ary << req.body.not_nil! if req.body
    end

    cmd = ary.first { return InvalidRequest.new }
    return CommandNotFound.new(cmd) if ! Redis::Cluster::Commands[cmd]?
    return InvalidRequest.new if ary.size < 2

    begin
      return CommandFound.new(ary, MediaType.parse(ext.capitalize))
    rescue
      return MediaNotFound.new(ext)
    end
  end
  
  def self.format(value : Redis::RedisValue, mime : MediaType)
    value.to_s
  end
end
