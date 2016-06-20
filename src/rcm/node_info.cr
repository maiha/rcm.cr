record Rcm::NodeInfo,
  sha1   : String,
  addr   : Addr,
  flags  : String,
  master : String,
  sent   : Int64,
  recv   : Int64,
  epoch  : Int64,
  status : String,
  slot   : Rcm::Slot do

  def_equals_and_hash sha1
  delegate host, port, to: addr
  
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

  def first_slot : Int32
    slot.slots.first {
      raise "[BUG] #{addr} has no slot_range"
    }
  end
  
  def to_s(io : IO)
    io << "[%s] (%s) %6s" % [sha1_6, addr, role]
  end
end
