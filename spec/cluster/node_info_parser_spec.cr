require "./spec_helper"

describe Redis::Cluster::NodeInfo do
  describe ".parse" do
    it "should parse in normal case" do
      node = Redis::Cluster::NodeInfo.parse <<-EOF
        5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
      EOF
      node.sha1.should eq("5ac5361")
      node.host.should eq("127.0.0.1")
      node.port.should eq(7001)
      node.slot.to_s.should eq("0-9999")
    end

    it "should accept multiple keyslots" do
      node = Redis::Cluster::NodeInfo.parse <<-EOF
        5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 5 8 10-15
      EOF
      node.slot.to_s.should eq("5,8,10-15")
    end

    describe "(IMPORTING)" do
      it "should support importing state (1 import)" do
        node = Redis::Cluster::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected [3194-<-39c926a7e99265467221bb527887d95d84f87893]
        EOF
        node.slot.to_s.should eq("3194<")
      end

      it "should support importing state (2 imports)" do
        node = Redis::Cluster::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected [5-<-39c926a7e99265467221bb527887d95d84f87893] [3194-<-39c926a7e99265467221bb527887d95d84f87893]
        EOF
        node.slot.to_s.should eq("5<,3194<")
      end
    end

    describe "(MIGRATING)" do
      it "should support migrating state" do
        node = Redis::Cluster::NodeInfo.parse <<-EOF
          7e24e6 127.0.0.1:7001 myself,master - 0 0 1 connected 100-200 [3194->-524246]
        EOF
        node.slot.to_s.should eq("100-200,3194>")
      end
    end

    it "should treat a empty host as 127.0.0.1" do
      node = Redis::Cluster::NodeInfo.parse <<-EOF
        5ac5361 :7001 myself,master - 0 0 0 connected 0-9999
      EOF
      node.host.should eq("127.0.0.1")
    end

    it "should raise when port part is missing" do
      expect_raises(Exception, /port/) do
        node = Redis::Cluster::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1: myself,master - 0 0 0 connected 0-9999
        EOF
      end
    end

    it "should raise when port part is not a number format" do
      expect_raises(Exception, /port/) do
        node = Redis::Cluster::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1:abc myself,master - 0 0 0 connected 0-9999
        EOF
      end
    end

    it "should parse bus-port format" do
      node = Redis::Cluster::NodeInfo.parse <<-EOF
        5ac5361 127.0.0.1:7001@7101 myself,master - 0 0 0 connected
      EOF
      node.sha1.should eq("5ac5361")
      node.host.should eq("127.0.0.1")
      node.port.should eq(7001)
      node.cport.should eq(7101)
    end
  end
end
