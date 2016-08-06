require "./spec_helper"

describe Rcm::Create do
  describe "for 3 nodes on 1 host" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.1:7002
      192.168.0.1:7003
      EOF

    it "creates 3 masters without cluster hints" do
      create = Rcm::Create.new(nodes.split)
      create.commands.select(&.is_a?(Rcm::Command::Addslots)).should eq([
        addslots("192.168.0.1:7001", "0-5461"),
        addslots("192.168.0.1:7002", "5462-10923"),
        addslots("192.168.0.1:7003", "10924-16383"),
      ])
    end

    it "creates 1 master and 2 slaves with masters 1 option" do
      commands = Rcm::Create.new(nodes.split, masters: 1).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).should eq([
        addslots("192.168.0.1:7001", "0-16383"),
      ])
      commands.select(&.is_a?(Rcm::Command::Replicate)).should eq([
        replicate("192.168.0.1:7002", "192.168.0.1:7001"),
        replicate("192.168.0.1:7003", "192.168.0.1:7001"),
      ])
    end

    it "creates 2 masters and 1 slave with masters 2 option" do
      commands = Rcm::Create.new(nodes.split, masters: 2).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).should eq([
        addslots("192.168.0.1:7001", "0-8191"),
        addslots("192.168.0.1:7002", "8192-16383"),
      ])
      commands.select(&.is_a?(Rcm::Command::Replicate)).should eq([
        replicate("192.168.0.1:7003", "192.168.0.1:7002"),
      ])
    end

    it "creates 3 masters with masters 3 option" do
      commands = Rcm::Create.new(nodes.split, masters: 3).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).should eq([
        addslots("192.168.0.1:7001", "0-5461"),
        addslots("192.168.0.1:7002", "5462-10923"),
        addslots("192.168.0.1:7003", "10924-16383"),
      ])
      commands.none?(&.is_a?(Rcm::Command::Replicate)).should be_true
    end

    it "creates 3 masters with masters 4 option" do
      # Best efforts for not enough nodes. should raise?
      commands = Rcm::Create.new(nodes.split, masters: 4).commands
      commands.select(&.is_a?(Rcm::Command::Addslots)).should eq([
        addslots("192.168.0.1:7001", "0-5461"),
        addslots("192.168.0.1:7002", "5462-10923"),
        addslots("192.168.0.1:7003", "10924-16383"),
      ])
      commands.none?(&.is_a?(Rcm::Command::Replicate)).should be_true
    end
  end
end
