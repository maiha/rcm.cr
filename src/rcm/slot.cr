module Rcm
  record Slot,
    label : String,
    set : Set(Int32) do
  
    FIRST = 0
    LAST  = 16383
    RANGE = (FIRST..LAST)
    SIZE  = RANGE.size

    def self.slot(key : String) : Int32
      (Crc16.crc16(key) % SIZE).to_i32
    end

    def self.parse(str : String) : Slot
      str = str.strip
      delimiter = /[,\s]+/
      case str
      when ""
        return Slot.new(str, Set(Int32).new)
      when delimiter
        names = str.split(delimiter).map(&.strip)
        slots = names.map{|s| parse(s).as(Slot) }
        name  = names.join(",")
        value = slots.reduce(Set(Int32).new) {|a,s| a.merge(s.set); a}
        return Slot.new(name, value)
      when /\A(\d+)\Z/
        return Slot.new("#{$1}", Set{$1.to_i})
      when /\A(\d+)(\.\.|-)(\d+)\Z/
        return Slot.new("#{$1}-#{$3}", ($1.to_i .. $3.to_i).to_set)
      when /\A(\.\.|-)(\d+)\Z/
        return Slot.new("#{FIRST}-#{$2}", (FIRST .. $2.to_i).to_set)
      when /\A(\d+)(\.\.|-)\Z/
        return Slot.new("#{$1}-#{LAST}", ($1.to_i .. LAST).to_set)
      else
        raise "invalid slot format: `#{str}`"
      end
    end

    delegate each, size, empty?, to: set
    
    def slots
      set.to_a
    end

    def to_s(io : IO)
      io << label
    end
  end

  def self.slot(key : String) : Int32
    Slot.slot(key)
  end
end
