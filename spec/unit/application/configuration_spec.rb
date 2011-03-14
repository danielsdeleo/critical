require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Application::Configuration do
  it "yields itself via a convenience method on the Critical module" do
    ::Critical.configure do |c|
      c.should equal ::Critical::Application::Configuration.instance
    end
  end

  it "returns itself via a convenience method on the Critical module" do
    ::Critical.config.should equal ::Critical::Application::Configuration.instance
  end

  describe "loading the config file" do
    before do
      @config = Critical::Application::Configuration.instance
      @config.reset!
      @stdout = StringIO.new
      @config.stub!(:stdout).and_return(@stdout)
    end

    it "successfully loads a valid configuration file" do
      $config_file_loaded = false
      @config.config_file = File.dirname(__FILE__) + "/../../fixtures/config/basic.rb"
      @config.read_config_file
      $config_file_loaded.should be_true
    end

    it "prints the help message with an explanation and exits if the config file doesn't exist" do
      @config.should_receive :exit
      conf = @config.config_file = File.dirname(__FILE__) + "/../../fixtures/config/no_such_thing_dude.rb"
      expanded = File.expand_path(conf)
      @config.read_config_file
      @stdout.string.should match Regexp.new("The configuration file you specified: #{expanded} doesn't exist")
    end

    it "prints the help message with an explanation and exits if the config file is actaully a directory or pipe or whatever" do
      @config.should_receive :exit
      conf = @config.config_file = File.dirname(__FILE__) + "/../../fixtures/config"
      expanded = File.expand_path(conf)
      @config.read_config_file
      @stdout.string.should match Regexp.new("The configuration file you specified: #{expanded} isn't a file")
    end
  end

  describe "reading command line options" do
    before do
      @config = Critical::Application::Configuration.instance
      @config.reset!
      @stdout = StringIO.new
      @config.stub!(:stdout).and_return(@stdout)
    end

    it "prints a banner and exits when given -h or --help" do
      @config.stub!(:argv).and_return(["-h"])
      @config.should_receive(:exit)
      @config.parse_opts
    end

    it "prints the version and exits when given -v or --version" do
      @config.stub!(:argv).and_return(["-v"])
      @config.should_receive(:exit)
      @config.parse_opts
    end

    it "adds a file or directory to the list of sourcse" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      @config.require(fixture_dir)
      @config.source_files.should == [File.expand_path(fixture_dir)]
    end

    it "adds multiple directories of sources" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      other_fixtures = File.dirname(__FILE__) + '/../../fixtures/more_source_files'
      @config.stub!(:argv).and_return(["-r", fixture_dir, "-r", other_fixtures])
      @config.parse_opts
      expected = [File.expand_path(fixture_dir), File.expand_path(other_fixtures)]
      @config.source_files.sort.should == expected.sort
    end

    it "sets the pidfile location" do
      @config.stub!(:argv).and_return(%w{-p /var/pids/critical.pid})
      @config.parse_opts
      @config.pidfile.should == "/var/pids/critical.pid"
    end

    it "specifies whether to run daemonized" do
      @config.stub!(:argv).and_return([])
      @config.parse_opts
      @config.daemonize?.should be_false

      @config.stub!(:argv).and_return(%w{-D})
      @config.parse_opts
      @config.daemonize?.should be_true
    end

    it "specifies if the application should run continuously" do
      @config.stub!(:argv).and_return([])
      @config.parse_opts
      @config.continuous?.should be_false

      @config.stub!(:argv).and_return(%w{-C})
      @config.parse_opts
      @config.continuous?.should be_true
    end

    it "sets the config file location" do
      @config.stub!(:argv).and_return(%w{-c /path/to/config/file})
      @config.parse_opts
      @config.config_file.should == "/path/to/config/file"
    end

    it "sets the logfile location" do
      pending "Not Implemented"
    end

    it "sets the log level" do
      @config.stub!(:argv).and_return(%w{-l FATAL})
      @config.parse_opts
      Loggable::Logger.instance.level.should == ::Logger::FATAL
    end
  end

  describe "in the configuration file" do
    before do
      @config = Critical::Application::Configuration.instance
      @config.reset!
      @stdout = StringIO.new
      @config.stub!(:stdout).and_return(@stdout)
    end

    it "allows the output dispatcher to be configured via #reporting" do
      dispatcher = nil
      @config.reporting do |report|
        dispatcher = report
      end
      dispatcher.should == Critical::OutputHandler::Dispatcher
    end

    it "allows the log formatter to be configured via log_format" do
      @config.log_format.should == Critical::Loggable::Formatters::Ruby
    end

  end
end
