describe LinuxAdmin::SystemdService do
  let(:command) { LinuxAdmin::Common.cmd(:systemctl) }

  before do
    @service = described_class.new 'foo'
  end

  describe "#running?" do
    it "checks service" do
      expect(LinuxAdmin::Common).to receive(:run)
        .with(command, :params => %w(status foo)).and_return(double(:success? => true))
      @service.running?
    end

    it "returns true when service is running" do
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:success? => true))
      expect(@service).to be_running
    end

    it "returns false when service is not running" do
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:success? => false))
      expect(@service).not_to be_running
    end
  end

  describe "#enable" do
    it "enables service" do
      expect(LinuxAdmin::Common).to receive(:run!) .with(command, :params => %w(enable foo))
      @service.enable
    end

    it "returns self" do
      expect(LinuxAdmin::Common).to receive(:run!) # stub out cmd invocation
      expect(@service.enable).to eq(@service)
    end
  end

  describe "#disable" do
    it "disables service" do
      expect(LinuxAdmin::Common).to receive(:run!).with(command, :params => %w(disable foo))
      @service.disable
    end

    it "returns self" do
      expect(LinuxAdmin::Common).to receive(:run!)
      expect(@service.disable).to eq(@service)
    end
  end

  describe "#start" do
    it "starts service" do
      expect(LinuxAdmin::Common).to receive(:run!).with(command, :params => %w(start foo))
      @service.start
    end

    it "enables the service if passed true" do
      expect(LinuxAdmin::Common).to receive(:run!).with(command, :params => %w(enable --now foo))
      @service.start(true)
    end

    it "returns self" do
      expect(LinuxAdmin::Common).to receive(:run!)
      expect(@service.start).to eq(@service)
    end
  end

  describe "#stop" do
    it "stops service" do
      expect(LinuxAdmin::Common).to receive(:run!).with(command, :params => %w(stop foo))
      @service.stop
    end

    it "returns self" do
      expect(LinuxAdmin::Common).to receive(:run!)
      expect(@service.stop).to eq(@service)
    end
  end

  describe "#restart" do
    it "restarts service" do
      expect(LinuxAdmin::Common).to receive(:run).with(command, :params => %w(restart foo)).and_return(double(:exit_status => 0))
      @service.restart
    end

    it "manually stops then starts service when restart fails" do
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:exit_status => 1))
      expect(@service).to receive(:stop)
      expect(@service).to receive(:start)
      @service.restart
    end

    it "returns self" do
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:exit_status => 0))
      expect(@service.restart).to eq(@service)
    end
  end

  describe "#reload" do
    it "reloads service" do
      expect(LinuxAdmin::Common).to receive(:run!).with(command, :params => %w(reload foo))
      expect(@service.reload).to eq(@service)
    end
  end

  describe "#status" do
    it "returns the service status" do
      status = "service status here"
      expect(LinuxAdmin::Common).to receive(:run)
        .with(command, :params => %w(status foo)).and_return(double(:output => status))
      expect(@service.status).to eq(status)
    end
  end

  describe "#show" do
    it "returns a hash of runtime information" do
      output = <<-EOS
MainPID=29189
ExecMainStartTimestamp=Wed 2017-02-08 13:49:57 EST
ExecStart={ path=/bin/sh ; argv[]=/bin/sh -c /bin/evmserver.sh start ; status=0/0 }
ExecStop={ path=/bin/sh ; argv[]=/bin/sh -c /bin/evmserver.sh stop ; status=0/0 }
ControlGroup=/system.slice/evmserverd.service
MemoryCurrent=2865373184
EOS

      hash = {
        "MainPID"                => 29_189,
        "ExecMainStartTimestamp" => Time.new(2017, 2, 8, 13, 49, 57, "-05:00"),
        "ExecStart"              => {"path" => "/bin/sh", "argv[]" => "/bin/sh -c /bin/evmserver.sh start", "status" => "0/0"},
        "ExecStop"               => {"path" => "/bin/sh", "argv[]" => "/bin/sh -c /bin/evmserver.sh stop", "status" => "0/0"},
        "ControlGroup"           => "/system.slice/evmserverd.service",
        "MemoryCurrent"          => 2_865_373_184
      }
      expect(LinuxAdmin::Common).to receive(:run!)
        .with(command, :params => %w(show foo)).and_return(double(:output => output))
      expect(@service.show).to eq(hash)
    end
  end
end
