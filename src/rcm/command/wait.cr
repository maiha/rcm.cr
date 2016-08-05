module Rcm::Command
  record Wait,
    sec : Float64 do

    include Executable

    def command
      "sleep #{sec}"
    end
  end
end
