require "./spec_helper"

private def addr(str)
  Rcm::Addr.parse(str)
end

private def addslots(node, slot, pass = nil)
  Rcm::Command::Addslots.new(addr(node), slot, pass)
end

private def meet(src, dst, pass = nil)
  Rcm::Command::Meet.new(addr(src), addr(dst), pass)
end

private def wait(sec)
  Rcm::Command::Wait.new(sec)
end

private def replicate(src, dst, pass = nil)
  Rcm::Command::Replicate.new(addr(src), addr(dst), pass)
end

describe Rcm::Create do
  it "generates rcm commands" do
    io = MemoryIO.new
    create = Rcm::Create.new(%w( 192.168.0.1:7001 192.168.0.1:7002 192.168.0.2:7001 ))
    create.dryrun(io)
    io.to_s.should eq <<-EOF
      rcm -h '192.168.0.1' -p 7002 meet '192.168.0.1:7001'
      rcm -h '192.168.0.2' -p 7001 meet '192.168.0.1:7001'
      rcm -h '192.168.0.1' -p 7001 addslots '0-8191'
      rcm -h '192.168.0.2' -p 7001 addslots '8192-16383'
      sleep 1.0
      rcm -h '192.168.0.1' -p 7002 replicate '192.168.0.2:7001'

      EOF
  end

  it "generates rcm commands with auth" do
    io = MemoryIO.new
    create = Rcm::Create.new(%w( 192.168.0.1:7001 192.168.0.1:7002 192.168.0.2:7001 ), pass: "secret")
    create.dryrun(io)
    io.to_s.should eq <<-EOF
      rcm -a 'secret' -h '192.168.0.1' -p 7002 meet '192.168.0.1:7001'
      rcm -a 'secret' -h '192.168.0.2' -p 7001 meet '192.168.0.1:7001'
      rcm -a 'secret' -h '192.168.0.1' -p 7001 addslots '0-8191'
      rcm -a 'secret' -h '192.168.0.2' -p 7001 addslots '8192-16383'
      sleep 1.0
      rcm -a 'secret' -h '192.168.0.1' -p 7002 replicate '192.168.0.2:7001'

      EOF
  end

  it "for 3 nodes on 3 hosts (no slaves)" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.2:7002
      192.168.0.3:7003
      EOF

    create = Rcm::Create.new(nodes.split)
    create.commands.should eq([
      meet("192.168.0.2:7002", "192.168.0.1:7001"),
      meet("192.168.0.3:7003", "192.168.0.1:7001"),
      addslots("192.168.0.1:7001", "0-5461"),
      addslots("192.168.0.2:7002", "5462-10923"),
      addslots("192.168.0.3:7003", "10924-16383"),
    ])
  end

  it "for 15 nodes on 5 hosts (a master has 2 slaves)" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.1:7002
      192.168.0.1:7003
      192.168.0.2:7001
      192.168.0.2:7002
      192.168.0.2:7003
      192.168.0.3:7001
      192.168.0.3:7002
      192.168.0.3:7003
      192.168.0.4:7001
      192.168.0.4:7002
      192.168.0.4:7003
      192.168.0.5:7001
      192.168.0.5:7002
      192.168.0.5:7003
      EOF

    create = Rcm::Create.new(nodes.split)
    create.commands.should eq([
      meet("192.168.0.1:7002", "192.168.0.1:7001"),
      meet("192.168.0.1:7003", "192.168.0.1:7001"),
      meet("192.168.0.2:7001", "192.168.0.1:7001"),
      meet("192.168.0.2:7002", "192.168.0.1:7001"),
      meet("192.168.0.2:7003", "192.168.0.1:7001"),
      meet("192.168.0.3:7001", "192.168.0.1:7001"),
      meet("192.168.0.3:7002", "192.168.0.1:7001"),
      meet("192.168.0.3:7003", "192.168.0.1:7001"),
      meet("192.168.0.4:7001", "192.168.0.1:7001"),
      meet("192.168.0.4:7002", "192.168.0.1:7001"),
      meet("192.168.0.4:7003", "192.168.0.1:7001"),
      meet("192.168.0.5:7001", "192.168.0.1:7001"),
      meet("192.168.0.5:7002", "192.168.0.1:7001"),
      meet("192.168.0.5:7003", "192.168.0.1:7001"),

      addslots("192.168.0.1:7001", "0-3276"),
      addslots("192.168.0.2:7001", "3277-6553"),
      addslots("192.168.0.3:7001", "6554-9830"),
      addslots("192.168.0.4:7001", "9831-13107"),
      addslots("192.168.0.5:7001", "13108-16383"),

      wait(1.0),

      replicate("192.168.0.1:7002", "192.168.0.5:7001"),
      replicate("192.168.0.1:7003", "192.168.0.4:7001"),
      replicate("192.168.0.2:7002", "192.168.0.1:7001"),
      replicate("192.168.0.2:7003", "192.168.0.5:7001"),
      replicate("192.168.0.3:7002", "192.168.0.2:7001"),
      replicate("192.168.0.3:7003", "192.168.0.1:7001"),
      replicate("192.168.0.4:7002", "192.168.0.3:7001"),
      replicate("192.168.0.4:7003", "192.168.0.2:7001"),
      replicate("192.168.0.5:7002", "192.168.0.4:7001"),
      replicate("192.168.0.5:7003", "192.168.0.3:7001"),
    ])
  end
end
