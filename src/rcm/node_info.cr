record Rcm::NodeInfo,
  sha1 : String,
  host : String,
  port : Int32 do

  def addr
    "#{host}:#{port}"
  end
end
