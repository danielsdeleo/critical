require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HeartbeatFile do

  before do
    @cleanup = []
  end

  after do
    @cleanup.each do |f|
      File.unlink(f.path) if File.exist?(f.path)
      f.close unless f.closed?
    end
  end

  it "is an unlinked file" do
    @cleanup << (f = HeartbeatFile.new)
    File.exist?(f.path).should be_false
  end

  it "creates the file with read/write for the current user only" do
    @cleanup << (f = HeartbeatFile.new)
    f.stat.mode.should == 0100600
  end

  it "always creates a new file instead of opening an existing one" do
    existing_file_path = HeartbeatFile.random_path
    unused_file_path   = HeartbeatFile.random_path

    # should only fail in the case that HeartbeatFile generated the same random path twice
    existing_file_path.should_not == unused_file_path

    HeartbeatFile.stub!(:random_path).and_return(existing_file_path, unused_file_path)
    existing_file_fd = File.new(existing_file_path, File::CREAT, 0600)
    @cleanup << existing_file_fd

    @cleanup << (f = HeartbeatFile.new)
    f.path.should == unused_file_path
  end

  it "has an alternating value to chmod itself" do
    @cleanup << (f = HeartbeatFile.new)
    f.alternator.should == 0
  end

  it "chmods itself when its owner is alive" do
    @cleanup << (f = HeartbeatFile.new)
    f.stat.mode.should == 0100600

    f.alive!
    f.stat.mode.should == 0100001

    f.alive!
    f.stat.mode.should == 0100000
  end

  it "computes the time since the last heartbeat" do
    @cleanup << (f = HeartbeatFile.new)

    f.time_since_heartbeat.should == 0

    f.stub!(:stat).and_return(mock("File::Stat 10s in the past", :ctime => (Time.now - 10)))
    f.time_since_heartbeat.should == 10
  end

end