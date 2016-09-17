module Rcm::Httpd::Actions::Clusters
  include Rcm::Httpd::RedisStat

  def index(env, redis)
    stats = env.info.stats
    ecr "stats"
  end

  private def mem_meter(stat : Stat)
    case stat
    when StatFound
      pct = stat.pct
      meter = %(<meter min="0" max="100" low="75" high="90" value="#{pct}">#{pct}%</meter> (#{pct}%))
    when StatError
      stat.error.message
    end
  end
  
  extend self
end
