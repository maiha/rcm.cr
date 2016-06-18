require "./spec_helper"

describe Rcm::Cluster::ShowNodes do
  info = Rcm::ClusterInfo.parse <<-EOF
    5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
    59894e2 127.0.0.1:7002 master - 0 1466174357779 1 connected 10000-16383
    EOF

  it "#show" do
    io = MemoryIO.new
    show = Rcm::Cluster::ShowNodes.new(info)
    show.show(io)
  end

  it "#show(count: true)" do
#    show = Rcm::Cluster::ShowNodes.new(info)
  end
end
