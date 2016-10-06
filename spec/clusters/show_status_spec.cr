require "../spec_helper"

private def remove_ansi_color(str : String)
  str.gsub(/\x1B\[[0-9;]*[mK]/, "")
end

describe Rcm::Cluster::ShowStatus do
  info = Redis::Cluster::ClusterInfo.parse <<-EOF
    5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
    59894e2 127.0.0.1:7002 master - 0 1466174357779 1 connected 10000-16383
    EOF

  it "#show(verbose: true)" do
    io = MemoryIO.new
    show = Rcm::Cluster::ShowStatus.new(info, Redis::Cluster::Counts.new, verbose: true)
    show.show(io)
    buf = remove_ansi_color(io.to_s).strip
    expected = <<-EOF
      [0-9999     ] M(127.0.0.1:7001) (orphaned)
      [10000-16383] M(127.0.0.1:7002) (orphaned)
      EOF
    buf.should eq(expected)
  end
end
