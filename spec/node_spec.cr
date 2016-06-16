require "./spec_helper"

describe Rcm::NodeInfo do
  describe ".parse" do
    it "builds nodes" do
      ret = <<-EOF
      7f193dc1e290415f153d4f90aee17197ba52171a 127.0.0.1:7002 master - 0 1466076881267 2 connected 5461-10922
      2afb4da9d68942a32676ca19e77492c4ba921d0f 127.0.0.1:7001 myself,master - 0 0 1 connected 0-5460
      053dd7389dc7e1ed897304518997e80a99f2896b 127.0.0.1:7003 master - 0 1466076880244 3 connected 10923-16383
      EOF

      nodes = Array(Rcm::NodeInfoParser).parse(ret)
      nodes.map(&.addr).sort.should eq(["127.0.0.1:7001", "127.0.0.1:7002", "127.0.0.1:7003"])
    end
  end
end
