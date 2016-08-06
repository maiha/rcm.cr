require "./spec_helper"

describe Rcm::Create do
  describe "explicitly masters=0" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.1:7002
      192.168.0.1:7003
      EOF

    it "just meet all together" do
      # This doesn't affect replication stuff, but builds cluster-nodes.
      commands = Rcm::Create.new(nodes.split, masters: 0).commands
      commands.map(&.class).uniq.should eq([Rcm::Command::Meet])
      commands.size.should eq 3
    end
  end
end
