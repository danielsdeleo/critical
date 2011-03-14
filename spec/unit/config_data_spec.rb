require File.expand_path('../../spec_helper.rb', __FILE__)
require 'critical/config_data'

describe ConfigData do
  before do
    @config_data = ConfigData.new("#{FIXTURES_DIR}/config_data")
    @config_data.load!
  end

  it "loads plain text files as arrays" do
    @config_data[:plain_text].should == %w[app_server load_balancer database]
  end

  it "loads JSON files as the corresponding ruby data structure" do
    @config_data[:json_file].should == {:webservice_ports=>[80, 443, 8080], :roles=>["appserver", "load_balancer"]}
  end

  it "supports indifferent access to the data items" do
    @config_data["json_file"].should_not be_nil
    @config_data["json_file"].should == @config_data[:json_file]
  end

  it "ignores non-json files with an extension" do
    # expect fixtures/config_data/ignore_me.foo not to show up here.
    @config_data.keys.should =~ %w[json_file plain_text]
  end
end
