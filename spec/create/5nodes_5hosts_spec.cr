require "./spec_helper"

describe Rcm::Create do
  describe "for 5 nodes on 5 hosts" do
    nodes = <<-EOF
      192.168.0.1:7001
      192.168.0.2:7001
      192.168.0.3:7001
      192.168.0.4:7001
      192.168.0.5:7001
      EOF

    # Rcm::Create
    #   for 5 nodes on 5 hosts
    #     creates 3 masters and 2 slaves with masters 3 option
    # ============================================================
    # find_master_for(192.168.0.4:7001)
    # ------------------------------------------------------------
    # # [slaves]
    # ------------------------------------------------------------
    # # [degree]
    # ------------------------------------------------------------
    #   192.168.0.1:7001: [0, 0, 0, 2]
    #   192.168.0.2:7001: [0, 0, 0, 1]
    #   192.168.0.3:7001: [0, 0, 0, 0]
    # ------------------------------------------------------------
    # => 192.168.0.3:7001
    # 
    # ============================================================
    # find_master_for(192.168.0.5:7001)
    # ------------------------------------------------------------
    # # [slaves]
    #   192.168.0.1:7001: []
    #   192.168.0.2:7001: []
    #   192.168.0.3:7001: ["192.168.0.4:7001"]
    # ------------------------------------------------------------
    # # [degree]
    #   (192.168.0.3, 192.168.0.4): 1
    # ------------------------------------------------------------
    #   192.168.0.1:7001: [0, 0, 0, 2]
    #   192.168.0.2:7001: [0, 0, 0, 1]
    #   192.168.0.3:7001: [0, 1, 0, 0]
    # ------------------------------------------------------------
    # => 192.168.0.2:7001

    it "creates 3 masters and 2 slaves with masters 3 option" do
      commands = Rcm::Create.new(nodes.split, masters: 3).commands
      commands.select(&.is_a?(Rcm::Command::Replicate)).should eq([
        replicate("192.168.0.4:7001", "192.168.0.3:7001"),
        replicate("192.168.0.5:7001", "192.168.0.2:7001"),
      ])
    end
    
    it "creates 2 masters and 3 slaves with masters 2 option" do
      commands = Rcm::Create.new(nodes.split, masters: 2).commands
      commands.select(&.is_a?(Rcm::Command::Replicate)).should eq([
        replicate("192.168.0.3:7001", "192.168.0.2:7001"),
        replicate("192.168.0.4:7001", "192.168.0.2:7001"),
        replicate("192.168.0.5:7001", "192.168.0.1:7001"),
      ])
    end
  end
end
