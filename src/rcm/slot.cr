module Rcm
  module Slot
    RANGE = (0_u16..16383_u16)
    SIZE  = RANGE.size
  
    def self.slot(key : String) : UInt16
      Crc16.crc16(key) % SIZE
    end
  end

  def self.slot(key : String) : UInt16
    Slot.slot(key)
  end
end
