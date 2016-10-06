require "../spec_helper"

describe Rcm::Cluster::ShowNodesList do
  info = Redis::Cluster::ClusterInfo.parse <<-EOF
    5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
    59894e2 127.0.0.1:7002 master - 0 1466174357779 1 connected 10000-16383
    EOF

  it "#show" do
    io = MemoryIO.new
    show = Rcm::Cluster::ShowNodesList.new(info, Redis::Cluster::Counts.new)
    show.show(io)
    buf = remove_ansi_color(io.to_s).strip
    expected = <<-EOF
      5ac536 [127.0.0.1:7001](?)  [0-9999     ] orphaned master(*)
      59894e [127.0.0.1:7002](?)  [10000-16383] orphaned master(*)
      EOF
    buf.should eq(expected)
  end
end
