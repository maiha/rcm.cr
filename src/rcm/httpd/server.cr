require "http/server"

module Rcm::Httpd
  class Server
    def initialize(@client : Client, @listen : Addr)
      @server = HTTP::Server.new(@listen.host, @listen.port) do |ctx|
        handle(ctx)
      end
    end
    
    def start
      @server.listen
    end

    private def handle(ctx : HTTP::Server::Context)
      case (req = RedisCommand.parse(ctx.request))
      when RedisCommand::CommandFound
        # curl http://127.0.0.1:3000/SET/hello/world
        # RedisCommand(@args=["SET", "hello", "world"])
        value = @client.command(req.args)
        ctx.response.print RedisCommand.format(value, req.mime)
      when RedisCommand::MediaNotFound
        ctx.response.status_code = 406
      when RedisCommand::CommandNotFound
        ctx.response.status_code = 400
      when RedisCommand::InvalidRequest
        ctx.response.status_code = 404
      end
    rescue err
      case err.message
      when /invalid password/
        ctx.response.status_code = 403
      else
        ctx.response.status_code = 500
      end
      ctx.response.print err.to_s
    end
  end
end
