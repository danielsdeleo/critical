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
    
    it "adds all of the files in a specified directory to the list of  source files" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      @config.require(fixture_dir)
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      @config.source_files.sort.should == expected.sort
    end
    
    it "adds the files in a specified directory to the list of source files specified on the command line" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      @config.stub!(:argv).and_return(["-r", fixture_dir])
      @config.parse_opts
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      @config.source_files.sort.should == expected.sort
    end
    
    it "adds multiple directories of sources" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      other_fixtures = File.dirname(__FILE__) + '/../../fixtures/more_source_files'
      @config.stub!(:argv).and_return(["-r", fixture_dir, "-r", other_fixtures])
      @config.parse_opts
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      expected += %w{four.rb five.rb six.rb}.map { |f| File.expand_path(other_fixtures + '/' + f) }
      @config.source_files.sort.should == expected.sort
    end
    
    it "specifies a pidfile" do
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
    
    it "allows an arbitrary string to be eval'd" do
      breadcrumb = rand(1023).to_s(16)
      @config.stub!(:argv).and_return(['-e', "Critical::TestHarness::ConfigSpecBreadcrumb = '#{breadcrumb}'"])
      @config.parse_opts
      Critical::TestHarness::ConfigSpecBreadcrumb.should == breadcrumb
    end
  end
end