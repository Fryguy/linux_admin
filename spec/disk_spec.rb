describe LinuxAdmin::Disk do
  describe "#local" do
    it "returns local disks" do
      expect(LinuxAdmin::Common).to receive(:run!).with(
        LinuxAdmin::Common.cmd(:lsblk),
        :params => {:b => nil, :d => nil, :n => nil, :p => nil, :o => "NAME,SIZE"}
      ).and_return(double("result", :output => "/dev/hda\n/dev/sda"))
      disks = LinuxAdmin::Disk.local
      paths = disks.collect { |disk| disk.path }
      expect(paths).to include('/dev/hda')
      expect(paths).to include('/dev/sda')
    end
  end

  describe "#size" do
    it "uses fdisk" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run!)
        .with(LinuxAdmin::Common.cmd(:fdisk),
              :params => {"-l" => nil})
        .and_return(double(:output => ""))
      disk.size
    end

    it "returns disk size" do
      fdisk = <<eos
Disk /dev/hda: 500.1 GB, 500107862016 bytes
255 heads, 63 sectors/track, 60801 cylinders, total 976773168 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x3ddb508b

   Device Boot      Start         End      Blocks   Id  System
 1      1259MB  81.8GB  80.5GB  primary   ntfs
 2      81.8GB  162GB   80.5GB  primary   ext4
 3      162GB   163GB   1074MB  logical   linux-swap(v1)
eos

      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      allow(LinuxAdmin::Common).to receive(:run!).and_return(double(:output => fdisk))
      expect(disk.size).to eq(500_107_862_016)
    end
  end

  describe "#partitions" do
    it "uses parted" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run)
        .with(LinuxAdmin::Common.cmd(:parted),
              :params => {nil => %w(--script /dev/hda print)}).and_return(double(:output => ""))
      disk.partitions
    end

    it "returns [] on non-zero parted rc" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => "", :exit_status => 1))
      expect(disk.partitions).to eq([])
    end

    context "with nvme parted output" do
      let(:parted_output) do
        <<~PARTED
          Model: NVMe Device (nvme)
          Disk /dev/nvme0n1: 512GB
          Sector size (logical/physical): 512B/512B
          Partition Table: msdos
          Disk Flags:

          Number  Start   End     Size    Type     File system  Flags
           1      1049kB  1075MB  1074MB  primary  ext4         boot
           2      1075MB  17.7GB  16.6GB  primary
           3      17.7GB  512GB   494GB   primary

        PARTED
      end

      it "sets partitons" do
        expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => parted_output))
        disk = LinuxAdmin::Disk.new(:path => "/dev/nvme0n1")
        partitions = disk.partitions

        expect(disk.model).to eq("nvme")

        expect(partitions[0].id).to eq(1)
        expect(partitions[0].disk).to eq(disk)
        expect(partitions[0].size).to eq(1_126_170_624.0)
        expect(partitions[0].start_sector).to eq(1_074_176.0)
        expect(partitions[0].end_sector).to eq(1_127_219_200.0)
        expect(partitions[0].partition_type).to eq('primary')
        expect(partitions[0].fs_type).to eq('ext4')
        expect(partitions[0].path).to eq('/dev/nvme0n1p1')
        expect(partitions[1].id).to eq(2)
        expect(partitions[1].disk).to eq(disk)
        expect(partitions[1].size).to eq(17_824_114_278.4)
        expect(partitions[1].start_sector).to eq(1_127_219_200.0)
        expect(partitions[1].end_sector).to eq(19_005_230_284.8)
        expect(partitions[1].partition_type).to eq('primary')
        expect(partitions[1].path).to eq('/dev/nvme0n1p2')
        expect(partitions[2].id).to eq(3)
        expect(partitions[2].disk).to eq(disk)
        expect(partitions[2].size).to eq(530_428_461_056.0)
        expect(partitions[2].start_sector).to eq(19_005_230_284.8)
        expect(partitions[2].end_sector).to eq(549_755_813_888.0)
        expect(partitions[2].partition_type).to eq('primary')
        expect(partitions[2].path).to eq('/dev/nvme0n1p3')
      end
    end

    context "with scsi parted output" do
      let(:parted_output) do
        <<~PARTED
          Model: ATA TOSHIBA MK5061GS (scsi)
          Disk /dev/sda: 500GB
          Sector size (logical/physical): 512B/512B
          Partition Table: msdos
          Disk Flags:

          Number  Start   End     Size    Type      File system     Flags
           1      1259kB  81.8GB  80.5GB  primary   ntfs
           2      81.8GB  162GB   80.5GB  primary   ext4
           3      162GB   163GB   1074MB  logical   linux-swap(v1)

        PARTED
      end

      it "sets partitons" do
        expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => parted_output))
        disk = LinuxAdmin::Disk.new(:path => "/dev/sda")
        partitions = disk.partitions

        expect(disk.model).to eq("scsi")

        expect(partitions[0].id).to eq(1)
        expect(partitions[0].disk).to eq(disk)
        expect(partitions[0].size).to eq(86_436_216_832.0)
        expect(partitions[0].start_sector).to eq(1_289_216.0)
        expect(partitions[0].end_sector).to eq(87_832_081_203.2)
        expect(partitions[0].partition_type).to eq('primary')
        expect(partitions[0].fs_type).to eq('ntfs')
        expect(partitions[0].path).to eq('/dev/sda1')
        expect(partitions[1].id).to eq(2)
        expect(partitions[1].disk).to eq(disk)
        expect(partitions[1].size).to eq(86_436_216_832.0)
        expect(partitions[1].start_sector).to eq(87_832_081_203.2)
        expect(partitions[1].end_sector).to eq(173_946_175_488)
        expect(partitions[1].partition_type).to eq('primary')
        expect(partitions[1].fs_type).to eq('ext4')
        expect(partitions[1].path).to eq('/dev/sda2')
        expect(partitions[2].id).to eq(3)
        expect(partitions[2].disk).to eq(disk)
        expect(partitions[2].size).to eq(1_126_170_624)
        expect(partitions[2].start_sector).to eq(173_946_175_488)
        expect(partitions[2].end_sector).to eq(175_019_917_312)
        expect(partitions[2].partition_type).to eq('logical')
        expect(partitions[2].fs_type).to eq('linux-swap(v1)')
        expect(partitions[2].path).to eq('/dev/sda3')
      end
    end
  end

  describe "#create_partitions" do
    before(:each) do
      @disk = LinuxAdmin::Disk.new(:path => '/dev/hda')
    end

    it "dispatches to create_partition" do
      expect(@disk).to receive(:create_partition).with("primary", "0%", "50%")
      @disk.create_partitions "primary", :start => "0%", :end => "50%"
    end

    context "multiple partitions specified" do
      it "calls create_partition for each partition" do
        expect(@disk).to receive(:create_partition).with("primary", "0%", "49%")
        expect(@disk).to receive(:create_partition).with("primary", "50%", "100%")
        @disk.create_partitions("primary", {:start => "0%",  :end => "49%"},
                                           {:start => "50%", :end => "100%"})
      end

      context "partitions overlap" do
        it "raises argument error" do
          expect{
            @disk.create_partitions("primary", {:start => "0%",  :end => "50%"},
                                               {:start => "49%", :end => "100%"})
          }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#create_partition" do
    before(:each) do
      # test disk w/ existing partition
      @disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      @disk.instance_variable_set(:@partitions,
                                  [LinuxAdmin::Partition.new(:id => 1,
                                                 :end_sector => 1024)])
      allow(@disk).to receive_messages(:has_partition_table? => true)
    end

    it "uses parted" do
      params = ['--script', '/dev/hda', 'mkpart', '-a', 'opt', 'primary', 1024, 2048]
      expect(LinuxAdmin::Common).to receive(:run!).with(LinuxAdmin::Common.cmd(:parted), :params => {nil => params})
      @disk.create_partition 'primary', 1024
    end

    it "accepts start/end params" do
      params = ['--script', '/dev/hda', 'mkpart', '-a', 'opt', 'primary', "0%", "50%"]
      expect(LinuxAdmin::Common).to receive(:run!).with(LinuxAdmin::Common.cmd(:parted), :params => {nil => params})
      @disk.create_partition 'primary', "0%", "50%"
    end

    context "missing params" do
      it "raises ArgumentError" do
        expect{
          @disk.create_partition 'primary'
        }.to raise_error(ArgumentError)

        expect{
          @disk.create_partition 'primary', '0%', '50%', 100
        }.to raise_error(ArgumentError)
      end
    end

    it "returns partition" do
      expect(LinuxAdmin::Common).to receive(:run!) # stub out call to parted
      partition = @disk.create_partition 'primary', 1024
      expect(partition).to be_an_instance_of(LinuxAdmin::Partition)
    end

    it "increments partition id" do
      expect(LinuxAdmin::Common).to receive(:run!) # stub out call to parted
      partition = @disk.create_partition 'primary', 1024
      expect(partition.id).to eq(2)
    end

    it "sets partition start to first unused sector on disk" do
      expect(LinuxAdmin::Common).to receive(:run!) # stub out call to parted
      partition = @disk.create_partition 'primary', 1024
      expect(partition.start_sector).to eq(1024)
    end

    it "stores new partition locally" do
      expect(LinuxAdmin::Common).to receive(:run!) # stub out call to parted
      expect {
        @disk.create_partition 'primary', 1024
      }.to change{@disk.partitions.size}.by(1)
    end

    it "creates partition table if missing" do
      allow(@disk).to receive_messages(:has_partition_table? => false)
      expect(@disk).to receive(:create_partition_table)
      expect(LinuxAdmin::Common).to receive(:run!)
      @disk.create_partition 'primary', 1024
    end
  end

  describe "#has_partition_table?" do
    it "positive case" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => "", :exit_status => 0))
      expect(disk).to have_partition_table
    end

    it "negative case" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      output = "\e[?1034h\r\rError: /dev/sdb: unrecognised disk label\n"
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => output, :exit_status => 1))
      expect(disk).not_to have_partition_table
    end
  end

  it "#create_partition_table" do
    disk = LinuxAdmin::Disk.new :path => '/dev/hda'
    options = {:params => {nil => %w(--script /dev/hda mklabel msdos)}}
    expect(LinuxAdmin::Common).to receive(:run!).with(LinuxAdmin::Common.cmd(:parted), options)
    disk.create_partition_table
  end

  describe "#clear!" do
    it "clears partitions" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run).and_return(double(:output => "")) # stub out call to cmds
      disk.partitions << LinuxAdmin::Partition.new

      expect(LinuxAdmin::Common).to receive(:run!)
      disk.clear!
      expect(disk.partitions).to be_empty
    end

    it "uses dd to clear partition table" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      expect(LinuxAdmin::Common).to receive(:run!)
        .with(LinuxAdmin::Common.cmd(:dd),
              :params => {'if=' => '/dev/zero', 'of=' => '/dev/hda',
                          'bs=' => 512, 'count=' => 1})
      disk.clear!
    end

    it "returns self" do
      disk = LinuxAdmin::Disk.new :path => '/dev/hda'
      allow(LinuxAdmin::Common).to receive(:run!) # stub out call to dd
      expect(disk.clear!).to eq(disk)
    end
  end

end
