require "http/server"

module Rcm::Httpd
  class Server
    include BasicAuth
    include Formatable

    def initialize(@client : Client, @listen : Bootstrap)
      @server = HTTP::Server.new(@listen.host, @listen.port) do |ctx|
        handle(ctx, listen.pass, @client.password)
      end
    end
    
    def start
      puts "Listening on http://#{@listen.host}:#{@listen.port}"
      @server.listen
    end

    private def handle(ctx : HTTP::Server::Context, user, pass)
      if authorized?(ctx, user, pass)
        process(ctx)
      end
    rescue err
      ctx.response.status_code = error_code(err)
      ctx.response.print err.to_s
    end

    private def process(ctx : HTTP::Server::Context)
      process ctx, RedisCommand.parse(ctx.request)
    end

    private def process(ctx, req : RedisCommand::Request)
      case req
      when RedisCommand::CommandFound
        # curl http://127.0.0.1:3000/SET/hello/world
        # RedisCommand(@args=["SET", "hello", "world"])
        value = @client.command(req.args)
        ctx.response.print format(req, value)
      else
        ctx.response.print format(req)
        ctx.response.status_code = error_code(req)
      end
    rescue err
      ctx.response.print format(err)
      ctx.response.status_code = error_code(req)
    end

    private def error_code(err) : Int32
      case err
      when RedisCommand::MediaNotFound   then 406
      when RedisCommand::CommandNotFound then 400
      when RedisCommand::InvalidRequest  then 404
      when Redis::Error then (err.message =~ /invalid password/) ? 403 : 500
      else 500
      end
    end
  end  
end
