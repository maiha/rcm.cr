require "./commands"

class Rcm::Client < Redis
  include Rcm::Commands
end
