module Rcm::Executable
  abstract def command : String

  def dryrun(io : IO)
    io << command << "\n"
  end

  def execute
    system(command)
  end

  def inspect(io : IO)
    dryrun(io)
  end
end
