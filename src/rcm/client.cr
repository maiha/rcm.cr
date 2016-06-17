require "./commands"
require "./helper"

class Rcm::Client < Redis
  include Rcm::Helper
  include Rcm::Commands
end
