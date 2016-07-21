require "./spec_helper"

describe Redis::Cluster::Slot do
  describe ".parse" do
    it "should convert '1234' to set" do
      Redis::Cluster::Slot.parse("1234").set.should eq Set{1234}
    end

    it "should convert '1234..1235' to set" do
      Redis::Cluster::Slot.parse("1234..1235").set.should eq Set{1234, 1235}
    end

    it "should convert '1234-1235' to set" do
      Redis::Cluster::Slot.parse("1234-1235").set.should eq Set{1234, 1235}
    end

    it "should convert '..2' to 0 origin set" do
      Redis::Cluster::Slot.parse("..2").set.should eq (0..2).to_set
    end

    it "should convert '-2' to 0 origin set" do
      Redis::Cluster::Slot.parse("-2").set.should eq (0..2).to_set
    end

    it "should convert '16300..' to 16383-ended set" do
      Redis::Cluster::Slot.parse("16300..").set.should eq (16300..16383).to_set
    end

    it "should convert '16300-' to 16383-ended set" do
      Redis::Cluster::Slot.parse("16300-").set.should eq (16300..16383).to_set
    end

    it "should treat ',' or ' ' as a multiple requests" do
      slot = Redis::Cluster::Slot.parse("..3 10,20..21 30-32,16380..")
      slot.set.should eq Set{0, 1, 2, 3, 10, 20, 21, 30, 31, 32, 16380, 16381, 16382, 16383}
    end
  end
end
