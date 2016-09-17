module Rcm::Httpd::Actions::Home
  def index(env)
    env.redis.ping              # to detect cluster or not

    if env.redis.cluster?
      Clusters.index(env, env.redis.cluster)
    elsif env.redis.standard?
      Standard.index(env, env.redis.standard)
    else
      "can't connect to redis server"
    end
  end

  extend self
end
