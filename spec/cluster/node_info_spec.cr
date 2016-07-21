require "./spec_helper"

describe Redis::Cluster::NodeInfo do
  describe ".parse" do
    it "works for empty inputs" do
      Array(Redis::Cluster::NodeInfo).parse("")
    end

    it "builds nodes" do
      ret = <<-EOF
      7fc615ac14ab67991831aba46672b128eb984aa7 127.0.0.1:7007 master - 0 1466124474343 7 connected 0-5460
      56f1954c1fa7b63fb631a872480dbf0a93bc8a9a 127.0.0.1:7004 slave,fail 2afb4da9d68942a32676ca19e77492c4ba921d0f 1466096807257 1466096806037 1 disconnected
      2afb4da9d68942a32676ca19e77492c4ba921d0f 127.0.0.1:7001 slave 7fc615ac14ab67991831aba46672b128eb984aa7 0 1466130784976 7 connected
      1c8f39f878e67d6685902d5b981be566599ebc21 127.0.0.1:7006 slave 053dd7389dc7e1ed897304518997e80a99f2896b 0 1466124474856 5 connected
      b80784b7f27cf30c8412760f3b546ba2e117ae67 127.0.0.1:7008 master - 0 1466124473320 0 connected
      6644fcff279cbf617f98105a3d854cd70e549b31 127.0.0.1:7009 master - 0 1466124473320 6 connected
      51fba73554f837bddd5a6c843330e8bc9446021e 127.0.0.1:7005 slave 7f193dc1e290415f153d4f90aee17197ba52171a 0 1466124473832 4 connected
      7f193dc1e290415f153d4f90aee17197ba52171a 127.0.0.1:7002 myself,master - 0 0 2 connected 5461-10922
      053dd7389dc7e1ed897304518997e80a99f2896b 127.0.0.1:7003 master - 0 1466124472808 3 connected 10923-16383
      EOF

      nodes = Array(Redis::Cluster::NodeInfo).parse(ret)
      nodes.map(&.addr.to_s).should eq(["127.0.0.1:7001", "127.0.0.1:7002", "127.0.0.1:7003", "127.0.0.1:7004", "127.0.0.1:7005", "127.0.0.1:7006", "127.0.0.1:7007", "127.0.0.1:7008", "127.0.0.1:7009"])
      nodes.map(&.port).should eq([7001, 7002, 7003, 7004, 7005, 7006, 7007, 7008, 7009])
      nodes.map(&.role).should eq(["slave", "master", "master", "slave,fail", "slave", "slave", "master", "master", "master"])
      nodes.map(&.sent).should eq([0, 0, 0, 1466096807257, 0, 0, 0, 0, 0])
      nodes.map(&.recv).should eq([1466130784976, 0, 1466124472808, 1466096806037, 1466124473832, 1466124474856, 1466124474343, 1466124473320, 1466124473320])
      nodes.map(&.slot.to_s).should eq(["", "5461-10922", "10923-16383", "", "", "", "0-5460", "", ""])
#      nodes.map(&.to_s).should eq(["2afb4d 127.0.0.1:7001 master",
#                                   "7f193d 127.0.0.1:7002 master",
#                                   "053dd7 127.0.0.1:7003 master"])

      nodes.select(&.fail?).map(&.addr.to_s).should eq(["127.0.0.1:7004"])
      nodes.select(&.disconnected?).map(&.addr.to_s).should eq(["127.0.0.1:7004"])
      nodes.select(&.standalone?).map(&.addr.to_s).should eq(["127.0.0.1:7008", "127.0.0.1:7009"])
    end
  end
end
