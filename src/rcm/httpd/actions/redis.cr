require "../formatable"

module Rcm::Httpd::Actions::Redis
  include Formatable

  def execute(env)
    req = RedisCommand.parse(env.request)
    case req
    when RedisCommand::CommandFound
      # curl http://127.0.0.1:3000/SET/hello/world
      # RedisCommand(@args=["SET", "hello", "world"])
      value = env.redis.command(req.args)
      env.response.print format(req, value)
    else
      env.response.print format(req)
      env.response.status_code = error_code(req)
    end
  rescue err
    env.response.print format(err)
    env.response.status_code = error_code(req)
  end

  private def error_code(err) : Int32
    case err
    when RedisCommand::MediaNotFound   then 406
    when RedisCommand::CommandNotFound then 400
    when RedisCommand::InvalidRequest  then 404
    when ::Redis::Error then (err.message =~ /invalid password/) ? 403 : 500
    else 500
    end
  end

  extend self
end
