module Rcm::Command
  abstract def addr : Addr
  abstract def opts : String
  delegate host, port, to: addr

  protected def cs
    addr.connection_string
  end

  def dryrun(io : IO)
    io << "rcm #{cs} " << opts << "\n"
  end

  def command(pass : String? = nil)
    auth = pass ? "-a '#{pass}'" : ""
    return "rcm #{auth} #{cs} #{opts}"
  end

  def execute(pass : String? = nil)
    system(command(pass))
  end

  def inspect(io : IO)
    dryrun(io)
  end
end
