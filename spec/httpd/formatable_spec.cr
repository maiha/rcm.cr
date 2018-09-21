require "./spec_helper"

include Rcm::Httpd
include Rcm::Httpd::Formatable

private def req(path)
  RedisCommand.parse(HTTP::Request.new("GET", path))
end

private def cmd(path)
  req(path).as(RedisCommand::CommandFound)
end

describe Rcm::Httpd::Formatable do
  describe "#format" do
    it "Nil" do
      format(cmd("/INCR/x/1.txt" ), nil).should eq("(nil)\n")
      format(cmd("/INCR/x/1.raw" ), nil).should eq("")
      format(cmd("/INCR/x/1.resp"), nil).should eq("$-1\r\n")
      format(cmd("/INCR/x/1.json"), nil).should eq(%({"incr":null}))
    end

    it "Int" do
      format(cmd("/INCR/x/1.txt" ), 1).should eq("1\n")
      format(cmd("/INCR/x/1.raw" ), 1).should eq("1")
      format(cmd("/INCR/x/1.resp"), 1).should eq(":1\r\n")
      format(cmd("/INCR/x/1.json"), 1).should eq(%({"incr":1}))
    end

    it "String" do
      format(cmd("/GET/x.txt" ), "a").should eq(%("a"\n))
      format(cmd("/GET/x.raw" ), "a").should eq("a")
      format(cmd("/GET/x.resp"), "a").should eq("$1\r\na\r\n")
      format(cmd("/GET/x.json"), "a").should eq(%({"get":"a"}))
    end

    it "Array(String)" do
      format(cmd("/MGET/a/b.txt" ), ["x", "y"]).should eq(%(["x", "y"]\n))
      format(cmd("/MGET/a/b.raw" ), ["x", "y"]).should eq("x\ny")
      format(cmd("/MGET/a/b.resp"), ["x", "y"]).should eq("*2\r\n$1\r\nx\r\n$1\r\ny\r\n")
      format(cmd("/MGET/a/b.json"), ["x", "y"]).should eq(%({"mget":["x","y"]}))
    end

    it "RedisCommand::Request" do
      req("/GET.txt").should eq(RedisCommand::InvalidRequest.new)
      req("/XXX.txt").should eq(RedisCommand::CommandNotFound.new("XXX"))

      format(req("/GET.txt")).should eq("InvalidRequest")
    end

    it "Exception" do
      format(Exception.new("some")).should eq("some")
      format(Redis::Error.new("some")).should eq("some")
    end
  end
end
