module Rcm::Command
  record Join,
    addrs : Array(Addr),
    pass : String? = nil do
    include Rcm::Executable

    def command
      args = %w( rcm )
      args << "-a '#{pass}'" if pass
      args << "join"
      args += addrs.map(&.to_s)
      return args.join(" ")
    end
  end
end
