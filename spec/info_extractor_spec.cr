require "./spec_helper"

describe "Rcm::InfoExtractor.extract" do
  info = Rcm::InfoExtractor.new(redis_info(fixtures("info.txt")))

  describe "(reserved words)" do
    it "version" do
      info.extract("v").should eq("ver(3.2.0)")
      info.extract("ver").should eq("ver(3.2.0)")
      info.extract("version").should eq("ver(3.2.0)")
    end

    it "mem" do
      info.extract("m").should eq("mem(2.57M;noev;0%)")
      info.extract("mem").should eq("mem(2.57M;noev;0%)")
      info.extract("memory").should eq("mem(2.57M;noev;0%)")
    end

    it "count" do
      info.extract("cnt").should eq("cnt(10000)")
      info.extract("count").should eq("cnt(10000)")
    end

    it "day" do
      info.extract("d").should eq("days(0)")
      info.extract("day").should eq("days(0)")
    end
  end

  describe "(no candidates)" do
    it "returns nil" do
      info.extract("xyz").should be_a(Rcm::InfoExtractor::NotFound)
    end
  end

  describe "(one candidate)" do
    it "returns the value when it is exactly matched" do
      info.extract("redis_version").should eq("redis_version(3.2.0)")
    end

    it "returns the value when it is prefix" do
      info.extract("redis_v").should eq("redis_version(3.2.0)")
    end

    it "supports label" do
      info.extract("redis_v{ver}").should eq("ver(3.2.0)")
    end
  end

  describe "(multiple candidates)" do
    # redis_git_sha1:00000000
    # redis_git_dirty:0
    it "returns all values in lcsv with shorten keys" do
      info.extract("redis_git_").should eq("redis_git(sha1:00000000, dirty:0)")
    end

    it "returns all values in lcsv with shorten keys" do
      info.extract("redis_g").should eq("redis_git(sha1:00000000, dirty:0)")
    end
  end
end
