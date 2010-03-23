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
    
  it "loads a configuration file"
  
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
    
    it "sets the default monitor interval"
    
    it "sets the logfile location"
    
    it "allows an arbitrary string to be eval'd" do
      breadcrumb = rand(1023).to_s(16)
      @config.stub!(:argv).and_return(['-e', "Critical::TestHarness::ConfigSpecBreadcrumb = '#{breadcrumb}'"])
      @config.parse_opts
      Critical::TestHarness::ConfigSpecBreadcrumb.should == breadcrumb
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
      @config.log_formatter.should == Critical::Loggable::Formatters::Ruby
    end
    
  end
end