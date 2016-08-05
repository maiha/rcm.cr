require "./executable"

module Rcm::Command
  include Executable

  abstract def pass : String?
  abstract def addr : Addr
  abstract def opts : String
  delegate host, port, to: addr

  def command
    args = %w( rcm )
    args << "-a '#{pass}'" if pass
    args << addr.connection_string
    args << opts
    return args.join(" ")
  end
end
