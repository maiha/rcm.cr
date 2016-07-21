require "./spec_helper"

describe Redis::Cluster::Addr do
  describe ".parse" do
    it "should treat a empty host as 127.0.0.1" do
      addr = Redis::Cluster::Addr.parse(":7001")
      addr.host.should eq("127.0.0.1")
    end

    it "should complete busport when missing" do
      addr = Redis::Cluster::Addr.parse(":7001")
      addr.port.should eq(7001)
      addr.cport.should eq(17001)
    end

    it "should raise when port part is missing" do
      expect_raises(Exception, /port/) do
        addr = Redis::Cluster::Addr.parse("127.0.0.1:")
      end
    end

    it "should raise when port part is not a number format" do
      expect_raises(Exception, /port/) do
        addr = Redis::Cluster::Addr.parse("127.0.0.1:abc")
      end
    end

    it "should parse bus-port format" do
      addr = Redis::Cluster::Addr.parse("127.0.0.1:7001@7101")
      addr.host.should eq("127.0.0.1")
      addr.port.should eq(7001)
      addr.cport.should eq(7101)
    end
  end

  describe "#connection_string" do
    it "should quote host" do
      addr = Redis::Cluster::Addr.parse("192.168.0.1:7000")
      addr.connection_string.should eq("-h '192.168.0.1' -p 7000")
    end

    it "should preserve 127.0.0.1 and 6379" do
      addr = Redis::Cluster::Addr.parse("127.0.0.1:6379")
      addr.connection_string.should eq("-h '127.0.0.1' -p 6379")
    end
  end

  describe "#connection_string_min" do
    it "should build -h and -p" do
      addr = Redis::Cluster::Addr.parse("192.168.0.1:7000")
      addr.connection_string_min.should eq("-h '192.168.0.1' -p 7000")
    end

    it "should remove 127.0.0.1" do
      addr = Redis::Cluster::Addr.parse("127.0.0.1:7000")
      addr.connection_string_min.should eq("-p 7000")
    end

    it "should remove 6379" do
      addr = Redis::Cluster::Addr.parse("192.168.0.1:6379")
      addr.connection_string_min.should eq("-h '192.168.0.1'")
    end

    it "should return empty when host and port are default values" do
      addr = Redis::Cluster::Addr.parse("127.0.0.1:6379")
      addr.connection_string_min.should eq("")
    end
  end
end
