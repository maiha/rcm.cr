require "../spec_helper"

private def show(info)
  io = IO::Memory.new
  show = Rcm::Cluster::ShowNodesList.new(info, Redis::Cluster::Counts.new)
  show.show(io)
  buf = remove_ansi_color(io.to_s).strip
  return buf
end

describe Rcm::Cluster::ShowNodesList do
  describe "#show" do
    it "(orphaned masters)" do
      info = Redis::Cluster::ClusterInfo.parse <<-EOF
        5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
        59894e2 127.0.0.1:7002 master - 0 1466174357779 1 connected 10000-16383
        EOF

      expected = <<-EOF
        5ac536 [127.0.0.1:7001](?)  [0-9999     ] orphaned master(*)
        59894e [127.0.0.1:7002](?)  [10000-16383] orphaned master(*)
        EOF
      show(info).should eq(expected)
    end

    it "(1 master has 2 slaves)" do
      info = Redis::Cluster::ClusterInfo.parse <<-EOF
        118f18 192.168.0.3:7001 master - 0 1475728302359 48 connected 6554-9830
        f5cdf2 192.168.0.4:7002 slave 118f18 0 1475728301859 48 connected
        5ad39a 192.168.0.5:7001 master - 0 1475728300856 52 connected 13108-16383
        fe3d87 192.168.0.3:7002 slave c0199b 0 1475728302359 46 connected
        fc4c59 192.168.0.2:7002 slave 3f300d 0 1475728300453 54 connected
        b2d538 192.168.0.4:7003 slave c0199b 0 1475728301357 46 connected
        f307be 192.168.0.2:7003 slave 5ad39a 0 1475728301357 52 connected
        b51e7b 192.168.0.5:7003 slave 118f18 0 1475728301859 48 connected
        3f300d 192.168.0.1:7001 myself,master - 0 0 54 connected 0-3276
        8e72a4 192.168.0.5:7002 slave 290cbf 0 1475728300856 50 connected
        421de2 192.168.0.1:7003 slave 290cbf 0 1475728302359 50 connected
        c0199b 192.168.0.2:7001 master - 0 1475728300354 46 connected 3277-6553
        f8a368 192.168.0.3:7003 slave 3f300d 0 1475728301859 54 connected
        b7acb3 192.168.0.1:7002 slave 5ad39a 0 1475728301859 52 connected
        290cbf 192.168.0.4:7001 master - 0 1475728301357 50 connected 9831-13107
        EOF

      expected = <<-EOF
        3f300d [192.168.0.1:7001](?)  [0-3276     ] master(*)
        fc4c59 [192.168.0.2:7002](?)    +slave(*) of 192.168.0.1:7001
        f8a368 [192.168.0.3:7003](?)    +slave(*) of 192.168.0.1:7001
        c0199b [192.168.0.2:7001](?)  [3277-6553  ] master(*)
        fe3d87 [192.168.0.3:7002](?)    +slave(*) of 192.168.0.2:7001
        b2d538 [192.168.0.4:7003](?)    +slave(*) of 192.168.0.2:7001
        118f18 [192.168.0.3:7001](?)  [6554-9830  ] master(*)
        f5cdf2 [192.168.0.4:7002](?)    +slave(*) of 192.168.0.3:7001
        b51e7b [192.168.0.5:7003](?)    +slave(*) of 192.168.0.3:7001
        290cbf [192.168.0.4:7001](?)  [9831-13107 ] master(*)
        8e72a4 [192.168.0.5:7002](?)    +slave(*) of 192.168.0.4:7001
        421de2 [192.168.0.1:7003](?)    +slave(*) of 192.168.0.4:7001
        5ad39a [192.168.0.5:7001](?)  [13108-16383] master(*)
        b7acb3 [192.168.0.1:7002](?)    +slave(*) of 192.168.0.5:7001
        f307be [192.168.0.2:7003](?)    +slave(*) of 192.168.0.5:7001
        EOF
      show(info).should eq(expected)
    end
  end
end
