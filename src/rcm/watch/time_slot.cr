module Rcm::Watch
  record TimeSlot,
    range : Range(Int32, Int32),
    slots : Hash(Int32, String)
end
