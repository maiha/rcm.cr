class Rcm::Advise::BetterReplication
  property advises, impact

  def initialize(@info : ClusterInfo, @counts : Counts)
    @advises = [] of Advise::Replicate
    @impact = ""
    analyze
  end

  def advise?
    @advises.any?
  end

  private def analyze
    active_masters = [] of NodeInfo
    active_slaves  = [] of NodeInfo
    rich_slaves    = [] of NodeInfo
    poor_master    = nil
    poor_slave_num = 1000

    become_poor_master = ->(master : NodeInfo, slaves : Array(NodeInfo)) {
      poor_master = master
      poor_slave_num = slaves.size
    }

    active = ->(node : NodeInfo) { @info.active?(node, @counts) }

    # scan replica counts
    @info.each_serving_masters_with_slaves do |master, slaves|
      unless active.call(master)
        # Ignore this dependencies when the master is down.
        # Because the cluster needs failover rather than rebalance
        next
      end

      # we should not count dead slaves for candidates
      slaves = slaves.select{|n| active.call(n)}

      active_masters << master
      active_slaves += slaves

      # find poor master
      if slaves.size < poor_slave_num
        become_poor_master.call(master, slaves)
      elsif slaves.size == poor_slave_num
        case poor_master
        when NodeInfo
          # if they have same slave counts, check first_slot for sorting
          if master.first_slot < poor_master.not_nil!.first_slot
            become_poor_master.call(master, slaves)
          end
        else
          become_poor_master.call(master, slaves)
        end
      end

      # find rich slaves
      if slaves.size > rich_slaves.size
        rich_slaves = slaves
      end
    end

    # No needs to advise because it seems an empty cluster
    return unless poor_master
    master = poor_master.not_nil!

    # No needs to advise because it seems no slaves exist
    return if rich_slaves.empty?
    slave = rich_slaves.sort{|a,b|
      if a.addr.port < b.addr.port
        -1
      elsif a.addr.port > b.addr.port
        1
      else
        a.addr.host <=> b.addr.host
      end
    }.last
    
    ideal_rf = 1 + active_slaves.size / active_masters.size # master + slaves
    poor_rf = poor_slave_num + 1
    if poor_rf < ideal_rf
      # Found that this relative `poor_master` is absolutely poor master.
      @advises << Replicate.new(master: master, slave: slave)
      @impact = "rf of '#{master.addr}': #{poor_rf} -> #{poor_rf + 1}"
    end
  end
end
