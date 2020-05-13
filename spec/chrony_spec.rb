describe LinuxAdmin::Chrony do
  CHRONY_CONF = <<-EOF
# commented server baz.example.net
pool bar.example.net iburst
server foo.example.net
server bar.example.net iburst
driftfile /var/lib/chrony/drift
makestep 10 3
rtcsync
EOF

  subject do
    allow(File).to receive(:exist?).and_return(true)
    described_class.new
  end

  describe ".new" do
    it "raises when the given config file doesn't exist" do
      expect { described_class.new("nonsense/file") }.to raise_error(LinuxAdmin::MissingConfigurationFileError)
    end
  end

  describe "#clear_servers" do
    it "removes all the server lines from the conf file" do
      allow(File).to receive(:read).and_return(CHRONY_CONF.dup)
      expect(File).to receive(:write) do |_file, contents|
        expect(contents).to eq "# commented server baz.example.net\ndriftfile /var/lib/chrony/drift\nmakestep 10 3\nrtcsync\n"
      end
      subject.clear_servers
    end
  end

  describe "#add_servers" do
    it "adds server lines to the conf file" do
      allow(File).to receive(:read).and_return(CHRONY_CONF.dup)
      expect(File).to receive(:write) do |_file, contents|
        expect(contents).to eq(CHRONY_CONF + "server baz.example.net iburst\nserver foo.bar.example.com iburst\n")
      end
      allow(subject).to receive(:restart_service_if_running)
      subject.add_servers("baz.example.net", "foo.bar.example.com")
    end

    it "restarts the service if it is running" do
      allow(File).to receive(:read).and_return(CHRONY_CONF.dup)
      allow(File).to receive(:write)

      chronyd_service = double
      expect(LinuxAdmin::Service).to receive(:new).with("chronyd").and_return(chronyd_service)
      expect(chronyd_service).to receive(:running?).and_return true
      expect(chronyd_service).to receive(:restart)
      subject.add_servers("baz.example.net", "foo.bar.example.com")
    end

    it "doesn't restart the service if it is not running" do
      allow(File).to receive(:read).and_return(CHRONY_CONF.dup)
      allow(File).to receive(:write)

      chronyd_service = double
      expect(LinuxAdmin::Service).to receive(:new).with("chronyd").and_return(chronyd_service)
      expect(chronyd_service).to receive(:running?).and_return false
      expect(chronyd_service).not_to receive(:restart)
      subject.add_servers("baz.example.net", "foo.bar.example.com")
    end
  end
end
