require "./spec_helper"

describe Rcm::Create do
  describe "all nodes in 1 host" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.1:7002
      192.168.0.1:7003
      EOF

    it "treat all nodes as master for default" do
      commands = Rcm::Create.new(nodes.split).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).size.should eq 3
    end
  end

  describe "3 nodes in 3 hosts" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.2:7001
      192.168.0.3:7001
      EOF

    it "creates 3 masters for default" do
      commands = Rcm::Create.new(nodes.split).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).size.should eq 3
    end
  end

  describe "5 nodes in 5 hosts" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.2:7001
      192.168.0.3:7001
      192.168.0.4:7001
      192.168.0.5:7001
      EOF

    it "creates 5 masters for default" do
      commands = Rcm::Create.new(nodes.split).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).size.should eq 5
    end
  end

  describe "5 nodes in 3 hosts" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.1:7002
      192.168.0.2:7001
      192.168.0.2:7002
      192.168.0.3:7001
      EOF

    it "creates 3 masters for default" do
      commands = Rcm::Create.new(nodes.split).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).size.should eq 3
    end
  end
end

