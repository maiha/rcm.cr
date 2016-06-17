module Rcm::Cluster
  class StepImport
    def initialize(@client : Client)
    end
    
    private def dryrun(io : IO, delimiter : String)
      count   = 0
      lineno  = 0
      linebuf = ""
      regex   = /#{delimiter}/
      
      io.each_line do |line|
        line = line.chomp
        linebuf = line
        lineno += 1
        ary = line.split(regex, 2)
        if ary.size == 2
          yield(ary[0], ary[1])
          count += 1
        else
          raise "expected element count = 2, but got #{ary.size}"
        end
      end
      return count
      
    rescue err
      raise "#{err}\n(line:#{lineno}) #{linebuf.inspect}"
    ensure
      io.rewind
    end
    
    def import(io : IO, delimiter : String, progress : Bool, count : Int32)
      # simulate
      total = dryrun(io, delimiter) { |key, val| @client.redis(key) }
      STDERR.puts ("[OK] check input file: %d entries" % total).colorize.green

      reporter = Periodical.reporter(progress, 3.seconds, ->{total})
      regex = /#{delimiter}/
      
      lines = [] of String
      flush = ->(i : Int32){
        return if lines.empty?
        lines.each do |line|
          ary = line.split(regex, 2)
          if ary.size == 2
            @client.set(ary[0], ary[1])
          else
            # skip
          end
        end
        lines.clear
        reporter.report(i)
      }
      
      cnt = 0
      io.each_line do |line|
        cnt += 1
        lines << line.chomp
        if cnt % count == 0
          flush.call(cnt)
        end
      end
      flush.call(cnt)
      reporter.done
    end
  end
end
