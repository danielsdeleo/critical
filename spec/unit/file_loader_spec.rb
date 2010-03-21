require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FileLoader do
  before do
    @context_obj = Object.new
  end
  
  it "loads a file in the context of a given object" do
    file_to_load = File.expand_path(File.dirname(__FILE__) + '/../fixtures/file_loader/file_loader_data')
    FileLoader.load_in_context(@context_obj, file_to_load)
    @context_obj.instance_variable_get(:@spy_variable).should == :pass
  end
  
  it "loads a file or directory in the context of a given object" do
    dir_to_load = File.expand_path(File.dirname(__FILE__) + '/../fixtures/file_loader')
    FileLoader.load_in_context(@context_obj, dir_to_load)
    @context_obj.instance_variable_get(:@spy_variable).should == :pass
    @context_obj.instance_variable_get(:@another_variable).should == :pass
  end
  
  it "raises an error when told to load a file that doesn't exist" do
    file_to_load = File.expand_path(File.dirname(__FILE__) + '/../fixtures/no_such_file')
    lambda {FileLoader.load_in_context(@context_obj, file_to_load)}.should raise_error(Critical::LoadError)
  end
end