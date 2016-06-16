require "./spec_helper"

describe Rcm::NodeInfo do
  describe ".parse" do
    it "builds nodes" do
      ret = <<-EOF
      7f193dc1e290415f153d4f90aee17197ba52171a 127.0.0.1:7002 master - 0 1466076881267 2 connected 5461-10922
      2afb4da9d68942a32676ca19e77492c4ba921d0f 127.0.0.1:7001 myself,master - 0 0 1 connected 0-5460
      053dd7389dc7e1ed897304518997e80a99f2896b 127.0.0.1:7003 master - 0 1466076880244 3 connected 10923-16383
      56f1954c1fa7b63fb631a872480dbf0a93bc8a9a 127.0.0.1:7004 slave 2afb4da9d68942a32676ca19e77492c4ba921d0f 0 1466089461937 1 connected
      EOF

      nodes = Array(Rcm::NodeInfo).parse(ret)
      nodes.map(&.addr).should eq(["127.0.0.1:7001", "127.0.0.1:7002", "127.0.0.1:7003", "127.0.0.1:7004"])
      nodes.map(&.port).should eq([7001, 7002, 7003, 7004])
      nodes.map(&.role).should eq(["master", "master", "master", "slave"])
      nodes.map(&.sent).should eq([0, 0, 0, 0])
      nodes.map(&.recv).should eq([0, 1466076881267, 1466076880244, 1466089461937])
      nodes.map(&.slot).should eq(["0-5460", "5461-10922", "10923-16383", ""])
#      nodes.map(&.to_s).should eq(["2afb4d 127.0.0.1:7001 master",
#                                   "7f193d 127.0.0.1:7002 master",
#                                   "053dd7 127.0.0.1:7003 master"])
    end
  end
end
