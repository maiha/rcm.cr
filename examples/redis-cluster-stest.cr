# Stress Test to redis cluster
#
# usage:
#   redis-cluster-stest 127.0.0.1:7000 10000
#
#     Sets data from 1 to given value ASAP to the cluster
#     where the node 127.0.0.1:7000 joins

require "../src/rcm"
require "colorize"

die   = ->(msg : String) { STDERR.puts msg; exit 1 }
usage = ->() {
  die.call("Usage: #{$0} BOOTSTRAP COUNT\n   ex) #{$0} 127.0.0.1:7000 10000")
}
boots = ARGV.shift { usage.call }
total = ARGV.shift { usage.call }.to_i

begin
  client = Redis::Cluster.new(boots)
  report = Periodical.reporter(true, 3.seconds, ->{total})

  (1..total).each do |i|
    key = i.to_s
    val = i.to_s
    client.set key, val
    report.report(i)
  end
  report.done
rescue err
  die.call(err.to_s.colorize.red.to_s)
ensure
  client.try(&.close)
end

