require "./spec_helper"

describe Redis::Cluster::Client do
  info = Redis::Cluster::ClusterInfo.parse <<-EOF
    5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
    59894e2 127.0.0.1:7002 master - 0 1466174357779 1 connected 10000-16383
    EOF
  cluster = Redis::Cluster.new(info)

  it "#get" do
    # TODO: prepare redis cluster on 7001,7002
    # cluster.get("foo")
  end
end
