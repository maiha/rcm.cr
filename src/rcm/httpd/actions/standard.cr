module Rcm::Httpd::Actions::Standard
  def index(env, redis)
    redis.info
  end

  extend self
end
