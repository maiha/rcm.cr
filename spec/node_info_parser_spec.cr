require "./spec_helper"

describe Rcm::NodeInfo do
  describe ".parse" do
    it "should parse in normal case" do
      node = Rcm::NodeInfo.parse <<-EOF
        5ac5361 127.0.0.1:7001 myself,master - 0 0 0 connected 0-9999
      EOF
      node.sha1.should eq("5ac5361")
      node.host.should eq("127.0.0.1")
      node.port.should eq(7001)
      node.slot.should eq("0-9999")
    end

    it "should treat a empty host as 127.0.0.1" do
      node = Rcm::NodeInfo.parse <<-EOF
        5ac5361 :7001 myself,master - 0 0 0 connected 0-9999
      EOF
      node.host.should eq("127.0.0.1")
    end

    it "should raise when port part is missing" do
      expect_raises(Exception, /port/) do
        node = Rcm::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1: myself,master - 0 0 0 connected 0-9999
        EOF
      end
    end

    it "should raise when port part is not a number format" do
      expect_raises(Exception, /port/) do
        node = Rcm::NodeInfo.parse <<-EOF
          5ac5361 127.0.0.1:abc myself,master - 0 0 0 connected 0-9999
        EOF
      end
    end
  end
end
