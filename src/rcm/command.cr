module Rcm::Command
  abstract def pass : String?
  abstract def addr : Addr
  abstract def opts : String
  delegate host, port, to: addr

  def dryrun(io : IO)
    io << command << "\n"
  end

  def command
    args = %w( rcm )
    args << "-a '#{pass}'" if pass
    args << addr.connection_string
    args << opts
    return args.join(" ")
  end

  def execute
    system(command)
  end

  def inspect(io : IO)
    dryrun(io)
  end
end
