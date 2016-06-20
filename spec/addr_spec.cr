require "./spec_helper"

describe Rcm::Addr do
  describe ".parse" do
    it "should treat a empty host as 127.0.0.1" do
      addr = Rcm::Addr.parse(":7001")
      addr.host.should eq("127.0.0.1")
    end

    it "should raise when port part is missing" do
      expect_raises(Exception, /port/) do
        addr = Rcm::Addr.parse("127.0.0.1:")
      end
    end

    it "should raise when port part is not a number format" do
      expect_raises(Exception, /port/) do
        addr = Rcm::Addr.parse("127.0.0.1:abc")
      end
    end
  end
end
