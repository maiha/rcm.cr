record Rcm::NodeInfo,
  sha1   : String,
  host   : String,
  port   : Int32,
  flags  : String,
  master : String,
  sent   : Int64,
  recv   : Int64,
  epoch  : Int64,
  status : String,
  slot   : String do

  def_equals_and_hash sha1
  
  val addr    = "#{host}:#{port}"
  val master? = !! flags["master"]?
  val slave?  = !! flags["slave"]?
  val fail?   = !! flags["fail"]?

  val connected?    = status.split(",").includes?("connected")
  val disconnected? = !! status["disconnected"]?

  def sha1_6
    "#{sha1}??????"[0..5]
  end

  def role
    %w( master slave ).map{|k| flags[k]?}.compact.first { "" }
  end
  
  def slot?
    !slot.empty?
  end

  def slot_range
    case slot
    when /\A(\d+)\Z/
      ($1.to_i .. $1.to_i)
    when /\A(\d+)-(\d+)\Z/
      ($1.to_i .. $2.to_i)
    else
      raise "[BUG] #{addr} has no slot_range: '#{slot}'"
    end
  end
  
  def to_s(io : IO)
    io << "[%s] (%s) %6s" % [sha1_6, addr, role]
  end
end
