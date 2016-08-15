require "./spec_helper"

private def parse(req)
  Rcm::Httpd::RedisCommand.parse(req)
end

private def get(path)
  parse(HTTP::Request.new("GET", path))
end

private def post(path, body = nil)
  parse(HTTP::Request.new("POST", path, body: body))
end

private def put(path, body = nil)
  parse(HTTP::Request.new("PUT", path, body: body))
end

private def found(args, ext)
  mime = Rcm::Httpd::MediaType.parse(ext.capitalize)
  Rcm::Httpd::RedisCommand::CommandFound.new(args, mime)
end

private def media_not_found(ext)
  Rcm::Httpd::RedisCommand::MediaNotFound.new(ext)
end

private def command_not_found(name)
  Rcm::Httpd::RedisCommand::CommandNotFound.new(name)
end

private def invalid_request
  Rcm::Httpd::RedisCommand::InvalidRequest.new
end

describe Rcm::Httpd::RedisCommand do
  describe ".parse" do
    it "GET method" do
      get("/FOO"           ).should eq(command_not_found("FOO"))
      get("/SET"           ).should eq(invalid_request)
      get("/SET/"          ).should eq(found(["SET", ""], "txt"))
      get("/SET/foo/1"     ).should eq(found(["SET", "foo", "1"], "txt"))
      get("/SET/foo/1.json").should eq(found(["SET", "foo", "1"], "json"))
      get("/SET/foo/1.raw" ).should eq(found(["SET", "foo", "1"], "raw" ))
      get("/SET/foo/1.foo" ).should eq(media_not_found("foo"))
    end

    it "POST method" do
      post("/SET"              ).should eq(invalid_request)
      post("/SET.raw"          ).should eq(invalid_request)
      post("/SET"         , "1").should eq(found(["SET", "1"], "txt"))
      post("/SET.raw"     , "1").should eq(found(["SET", "1"], "raw"))
      post("/SET/"             ).should eq(found(["SET", ""], "txt"))
      post("/SET/.raw"         ).should eq(found(["SET", ""], "raw"))
      post("/SET/"        , "1").should eq(found(["SET", ""   , "1"], "txt"))
      post("/SET/.raw"    , "1").should eq(found(["SET", ""   , "1"], "raw"))
      post("/SET/foo"     , "1").should eq(found(["SET", "foo", "1"], "txt"))
      post("/SET/foo.json", "1").should eq(found(["SET", "foo", "1"], "json"))
      post("/SET/foo.raw" , "1").should eq(found(["SET", "foo", "1"], "raw" ))
      post("/SET/foo/1.raw"    ).should eq(found(["SET", "foo", "1"], "raw" ))
      post("/SET/foo.foo" , "1").should eq(media_not_found("foo"))
    end

    it "PUT method" do
      put("/SET"              ).should eq(invalid_request)
      put("/SET/"        , "1").should eq(found(["SET", "", "1"], "txt"))
      put("/SET/foo"     , "1").should eq(found(["SET", "foo", "1"], "txt"))
      put("/SET/foo.json", "1").should eq(found(["SET", "foo", "1"], "json"))
      put("/SET/foo.raw" , "1").should eq(found(["SET", "foo", "1"], "raw" ))
      put("/SET/foo.foo" , "1").should eq(media_not_found("foo"))
    end
  end
end
