require "../spec_helper"

describe Rcm::Advise::BetterReplication do
  describe "(no data)" do
    it "#advise?" do
      info = load_cluster_info("nodes/empty.nodes")
      adviser = Rcm::Advise::BetterReplication.new(info, Rcm::Counts.new{ 0_i64 })
      adviser.advise?.should eq false
    end

    it "#advise" do
      info = load_cluster_info("nodes/empty.nodes")
      adviser = Rcm::Advise::BetterReplication.new(info, Rcm::Counts.new{ 0_i64 })
      adviser.advises.map(&.to_s).should eq([] of String)
    end
  end

  describe "(unbalanced slaves)" do
    info = load_cluster_info("nodes/m6s18r2-3.nodes")
    adviser = Rcm::Advise::BetterReplication.new(info, Rcm::Counts.new{ 0_i64 })

    it "#advise?" do
      adviser.advise?.should eq true
    end

    it "#advises" do
      adviser.advises.map(&.to_s).should eq(["rcm -h '127.0.0.1' -p 7015 REPLICATE 127.0.0.1:7016"])
    end
  end
end
