require "../spec_helper"

describe Rcm::Cluster::ShowSchema do
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

  it "#show" do
    io = MemoryIO.new
    show = Rcm::Cluster::ShowSchema.new(info)
    show.show(io)
    buf = remove_ansi_color(io.to_s).strip
    expected = <<-EOF
      [0-3276     ] 192.168.0.1:7001 192.168.0.2:7002 192.168.0.3:7003
      [3277-6553  ] 192.168.0.2:7001 192.168.0.3:7002 192.168.0.4:7003
      [6554-9830  ] 192.168.0.3:7001 192.168.0.4:7002 192.168.0.5:7003
      [9831-13107 ] 192.168.0.4:7001 192.168.0.5:7002 192.168.0.1:7003
      [13108-16383] 192.168.0.5:7001 192.168.0.1:7002 192.168.0.2:7003
      EOF
    buf.should eq(expected)
  end
end
