require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Application::Configuration do
  it "yields itself via a convenience method on the Critical module" do
    ::Critical.configure do |c|
      c.should equal ::Critical::Application::Configuration.instance
    end
  end
  
  it "returns itself via a convenience method on the Critical module" do
    ::Critical.configuration.should equal ::Critical::Application::Configuration.instance
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
      @config.parse_argv
    end
    
    it "prints the version and exits when given -v or --version" do
      @config.stub!(:argv).and_return(["-v"])
      @config.should_receive(:exit)
      @config.parse_argv
    end
    
    it "adds all of the files in a specified directory to the list of metric source files" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      @config.metric_directory(fixture_dir)
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      @config.metric_files.sort.should == expected.sort
    end
    
    it "adds the files in a specified directory to the list of metric source files specified on the command line" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      @config.stub!(:argv).and_return(["-m", fixture_dir])
      @config.parse_argv
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      @config.metric_files.sort.should == expected.sort
    end
    
    it "adds multiple directories of metric sources" do
      fixture_dir = File.dirname(__FILE__) + '/../../fixtures/some_source_files'
      other_fixtures = File.dirname(__FILE__) + '/../../fixtures/more_source_files'
      @config.stub!(:argv).and_return(["-m", fixture_dir, "-m", other_fixtures])
      @config.parse_argv
      expected = %w{one.rb two.rb three.rb}.map {|f| File.expand_path(fixture_dir + '/' + f)}
      expected += %w{four.rb five.rb six.rb}.map { |f| File.expand_path(other_fixtures + '/' + f) }
      @config.metric_files.sort.should == expected.sort
    end
  end
end