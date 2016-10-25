module Rcm::Cluster
  module NodesHelper
    # sort slaves by port and host for durability pretty printing
    private def sort_slaves(nodes)
      nodes.sort {|a,b|
        case a.port <=> b.port
        when 0 then a.host <=> b.host
        else a.port <=> b.port
        end
      }
    end

    private def wait_for_condition(timeout, interval, hint = "timeout")
      loop do
        raise hint if Time.now > timeout
        break if yield == true
        sleep interval
      end
    end
  end
end
