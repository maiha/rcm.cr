module Rcm
  class ClusterInfo
    def self.parse(nodes_str) : ClusterInfo
      ClusterInfo.new(Array(Rcm::NodeInfo).parse(nodes_str))
    end

    class NodeNotFound < Exception ; end
    class NodeNotUniq  < Exception ; end
    
    property nodes, slot2nodes, slave_deps
    
    @slot2nodes : Hash(Int32, NodeInfo)
    @slave_deps : Hash(NodeInfo, Array(NodeInfo))
    
    def initialize(@nodes : Array(NodeInfo))
      @slot2nodes = build_slot2nodes
      @slave_deps = build_slave_deps
    end

    def slaves : Array(NodeInfo)
      nodes.select(&.slave?)
    end

    def acked_slaves : Array(NodeInfo)
      slave_deps.values.flatten
    end

    def serving_masters : Array(NodeInfo)
      nodes.select(&.serving?).sort_by(&.first_slot)
    end

    def orphaned_masters(counts : Hash(NodeInfo, Int64))
      masters = [] of NodeInfo
      each_serving_masters_with_slaves do |master, slaves|
        next if slaves.any?{|slave| counts[slave] >= 0}
        masters << master
      end
      return masters
    end

    # odd state: this slave belongs to another slave (What's this?)
    def orphaned_slaves
      set = slaves.to_set
      slaves.select{|s| set.includes?(s)}
    end

    def each_serving_masters_with_slaves
      deps = slave_deps
      serving_masters.each do |master|
        slaves = deps.fetch(master) {[] of NodeInfo}
        yield({master, slaves})
      end
    end

    def open_slots : Array(Int32)
      Slot::RANGE.to_a - slot2nodes.keys
    end

    def find_node_by(name : String) : NodeInfo
      if name =~ /[\.:]/
        find_node_by_addr(name)
      else
        find_node_by_sha1(name)
      end
    end

    def master_addr(node) : String
      find_node_by(node.master).addr.to_s rescue "(#{node.sha1_6})"
    end
    
    private def build_slave_deps : Hash(NodeInfo, Array(NodeInfo))
      slaves = {} of NodeInfo => Array(NodeInfo)
      nodes.each do |node|
        if node.slave? && !node.master.empty?
          master = find_node_by(node.master)
          slaves[master] ||= [] of NodeInfo
          slaves[master] << node
        end
      end

      # remove past masters that is regarded as a master but is now a slave
      slaves.keys.each do |node|
        slaves.delete(node) if node.slave?
      end
      
      return slaves
    end

    private def build_slot2nodes
      Hash(Int32, NodeInfo).new.tap {|hash|
        nodes.each do |node|
          next unless node.master? && node.slot?
          node.slot.each do |slot|
            hash[slot] = node
          end
        end
      }
    end

    def find_node_by_addr(addr)
      port = nil
      case addr
      when /(.*):\Z/
        host = $1
      when /(.*):(.*)/
        host = $1
        port = $2.to_i rescue raise "given port `#{$2}` is not a number"
      else
        host = addr
      end
      
      found = nodes.select{|n|
        (n.host.starts_with?(host)) && (port.nil? || n.port == port)
      }
      case found.size
      when 0
        possible = nodes.map(&.addr).join(", ")
        raise NodeNotFound.new("node not found: `#{addr}`\n(possible: #{possible})")
      when 1
        return found.first.not_nil!
      else
        possible = nodes.map(&.addr).join(", ")
        raise NodeNotUniq.new("node not uniq: `#{addr}`\n(possible: #{possible})")
      end
    end

    def find_node_by_sha1(sha1)
      found = nodes.select{|n| n.sha1 =~ /\A#{sha1}/}
      case found.size
      when 0
        possible = nodes.map(&.sha1_6).join(", ")
        raise NodeNotFound.new("node not found: `#{sha1}`\n(possible: #{possible})")
      when 1
        return found.first.not_nil!
      else
        possible = found.map(&.sha1_6).join(", ")
        raise NodeNotUniq.new("node not uniq: `#{sha1}`\n(possible: #{possible})")
      end
    end
  end
end
