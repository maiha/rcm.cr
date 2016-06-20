module Rcm
  class InfoExtractor
    def self.extract(hash, field)
      InfoExtractor.new(hash).extract(field)
    end

    def initialize(@hash : Hash(String, String))
    end

    record Search,
      field : String,
      label : String?
      
    record Common,
      prefix : String,
      length : Int32
      
    record NotFound,
      search : Search do
      def to_s(io : IO)
        io << "#{search.label || search.field}(not found)".colorize.yellow
      end
    end

    alias Value = String | NotFound

    # process reserved words
    private def preprocess_field(field : String)
      case field
      when "v", /\Aver/
        return "redis_version{ver}"
      when "d", /\Aday/
        return "uptime_in_days{days}"
      else
        return field
      end
    end
    
    def extract(field : String)
      field = preprocess_field(field)

      case field
      when /\A(.+?)\{(.+)\}\Z/
        search = Search.new(field: $1, label: $2)
      else
        search = Search.new(field: field, label: nil)
      end
      extract(search)
    end

    def extract(search : Search)
      # preprocess for reserved words
      case search.field
      when "cnt", "count"
        return extract_count(Search.new(field: "count", label: "cnt"))
      when "m", "mem", "memory"
        return extract_memory(Search.new(field: "memory", label: "mem"))
      end
      
      # search prefixed
      candidates = @hash.keys.select{|k| k.starts_with?(search.field)}
      case candidates.size
      when 0 
        # no matched
        return NotFound.new(search)
      else
        # multiple matched
        common = find_common_prefix_size(candidates)

        # special case: ["", "_a", "_b"] should be "foo(val, a:..., b:)"
        lcsv = candidates.map{|key|
          k = "#{key[common.length..-1]}".sub(/\A_/, "")
          v = "#{@hash[key]}"
          k.empty? ? v : "#{k}:#{v}"
        }.join(", ")

        if search.label.nil? && common.prefix.empty?
          return lcsv
        else
          return "%s(%s)" % [search.label || common.prefix, lcsv]
        end
      end
    end

    # [input]
    #   redis_git_sha1:00000000
    #   redis_git_dirty:0
    # [output]
    #   sha1:00000000, dirty:0
    private def find_common_prefix_size(candidates)
      parts = candidates.map{|s| s.split("_")}
      found = ->(i : Int32){ parts[0][0..i].join("_").size }
      lasti = parts.map(&.size).min
      # [["redis", "git", "sha1"],
      #  ["redis", "git", "dirty"]]
      (0 ...lasti).each do |pi|
        v = parts[0][pi]
        parts.each do |ary|
          if ary[pi] != v
            return Common.new("", 0) if pi == 0
            return Common.new(parts[0][0..pi-1].join("_"), found.call(pi-1))
          end
        end
      end
      return Common.new(parts[0][0..lasti].join("_"), found.call(lasti))
    end

    private def extract_memory(search)
      cur = @hash.fetch("used_memory_human"){ "?" }
      max = @hash.fetch("maxmemory_human") { "?" }

      pct = "%d" % (@hash["used_memory"].to_i64 * 100 / @hash["maxmemory"].to_i64) rescue "?"
      pol = @hash["maxmemory_policy"].sub("volatile","v").sub("allkeys","a").sub("noeviction","noev").sub("random","rnd") rescue "?"
        
      return "mem(#{cur};#{pol};#{pct}%)"
    end

    private def extract_count(search)
      # TODO: DRYUP with `Redis::Commands#count`
      cnt = case @hash.fetch("db0") { "" }
            when /^keys=(\d+)/m
              $1.to_i64
            else
              0.to_i64
            end
      return "cnt(#{cnt})"
    rescue err : Errno
      return NotFound.new(search)
    end
  end
end
