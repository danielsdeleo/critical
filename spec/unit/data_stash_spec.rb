require File.expand_path('../../spec_helper', __FILE__)
require 'critical/data_stash'

module TestHarness
  class DataStashDSLUser
    include Critical::DataStashDSL
    attr_reader :safe_str
    def initialize(safe_str)
      @safe_str = safe_str
    end
  end
end

describe DataStash do
  before do
    File.unlink('/tmp/data_stash_spec') rescue nil
    @data_stash = DataStash.new("/tmp/data_stash_spec")
  end

  it "stores data" do
    @data_stash.save("this is a stored message")
    @data_stash.load.should == "this is a stored message"
  end

  it "makes data available to other processes" do
    @data_stash.save("a stored message")
    other_process = fork do
      begin
        DataStash.new("/tmp/data_stash_spec").load.should == "a stored message"
      rescue Exception => e
        STDERR.puts(e)
        exit! 23
      else
        exit! 0
      end
    end

    pid, status = Process.waitpid2(other_process)
    status.exitstatus.should == 0
  end

  it "returns nil if there is no data yet" do
    @data_stash.load.should be_nil
  end
end

describe DataStashDSL do
  before do
    @dsl = TestHarness::DataStashDSLUser.new("dsl_user_strname")
  end

  it "creates a stash using the includer's safe_str" do
    # TODO: this path needs to be configurable
    # should be in /var/cache/critical
    @dsl.stash.path.should == '/tmp/critical/stash/dsl_user_strname'
  end

  it "creates the stash directory if it does not exist" do
    Dir.rmdir("/tmp/critical/stash") rescue nil
    Dir.rmdir("/tmp/critical") rescue nil
    @dsl.stash
    File.directory?('/tmp/critical/stash').should be_true
  end
end

