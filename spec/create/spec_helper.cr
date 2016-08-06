require "../spec_helper"

protected def addr(str)
  Rcm::Addr.parse(str)
end

protected def addslots(node, slot, pass = nil)
  Rcm::Command::Addslots.new(addr(node), slot, pass)
end

protected def meet(src, dst, pass = nil)
  Rcm::Command::Meet.new(addr(src), addr(dst), pass)
end

protected def wait(sec)
  Rcm::Command::Wait.new(sec)
end

protected def replicate(src, dst, pass = nil)
  Rcm::Command::Replicate.new(addr(src), addr(dst), pass)
end
