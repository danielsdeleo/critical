require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Critical
  module TestHarness
    class LoggingImplementor
      include Loggable
    end
  end
end

describe Loggable do
  before do
    @io = StringIO.new
    @logist = TestHarness::LoggingImplementor.new
    @logist.log.stub!(:io_out).and_return(@io)
    @logist.log.reset!
  end
  
  it "logs using the pretty printer" do
    @logist.log.debug :foo => :bar
    @io.string.should match Regexp.escape(':message=>{:foo=>:bar}')
  end
  
  it "implements debug logging" do
    @logist.log.debug :foo => :debug
    @io.string.should match Regexp.escape(':message=>{:foo=>:debug}')
    @io.string.should match Regexp.escape(':severity=>"DEBUG"')
  end
  
  it "implements info logging" do
    @logist.log.info :foo => :info
    @io.string.should match Regexp.escape(':message=>{:foo=>:info}')
    @io.string.should match Regexp.escape(':severity=>"INFO"')
  end
  
  it "implements warn logging" do
    @logist.log.warn :foo => :warn
    @io.string.should match Regexp.escape(':message=>{:foo=>:warn}')
    @io.string.should match Regexp.escape(':severity=>"WARN"')
  end
  
  it "provides warning as an alias for warn" do
    @logist.log.warning :foo => :warning
    @io.string.should match Regexp.escape(':message=>{:foo=>:warning}')
    @io.string.should match Regexp.escape(':severity=>"WARN"')
  end
  
  it "implements error logging" do
    @logist.log.error :foo => :error
    @io.string.should match Regexp.escape(':message=>{:foo=>:error}')
    @io.string.should match Regexp.escape(':severity=>"ERROR"')
  end
  
  it "implements fatal logging" do
    @logist.log.fatal :foo => :fatal
    @io.string.should match Regexp.escape(':message=>{:foo=>:fatal}')
    @io.string.should match Regexp.escape(':severity=>"FATAL"')
  end
  
  it "allows logging fields to be excluded" do
    Critical::Loggable::Formatters::Ruby.include_fields :message, :severity
    @logist.log.error :foobar => :epic_error
    @io.string.should match Regexp.escape(':message=>{:foobar=>:epic_error}')
    @io.string.should match Regexp.escape(':severity=>"ERROR"')
    @io.string.should_not match /:time/
    @io.string.should_not match /:sender/
  end
  
  it "takes a block for the log message" do
    @logist.log.debug { "A huge freakin string" }
    @io.string.should match Regexp.escape(':message=>"A huge freakin string"')
  end
  
  
end