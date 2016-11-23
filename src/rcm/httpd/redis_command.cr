require "http/server"

module Rcm::Httpd::RedisCommand
  module Request
  end

  record CommandFound, args : Array(String), mime : MediaType do
    include Request
    def name
      args.first
    end
  end

  record CommandNotFound, name : String do
    include Request
  end

  record MediaNotFound, ext  : String do
    include Request
  end

  record InvalidRequest do
    include Request
  end

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
      ary << req.body.not_nil!.gets_to_end if req.body
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
end
