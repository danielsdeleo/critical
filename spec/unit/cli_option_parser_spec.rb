require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestHarness
  class CLIOptUser
    extend  CLIOptionParser::ClassMethods
    include CLIOptionParser::InstanceMethods
    
  end
end

describe CLIOptionParser do
  before do
    @cli_opt_user_class = Class.new(TestHarness::CLIOptUser)
  end
  
  def define_method_on_opt_user(method_name)
    @cli_opt_user_class.class_eval <<-EVAL
      def #{method_name}
        @#{method_name} = "hello from #{method_name}"
      end
    EVAL
  end
  
  it "takes an option's description" do
    @cli_opt_user_class.option "prints 'foo' to the screen"
    define_method_on_opt_user(:print_foo)
    @cli_opt_user_class.valid_options["--print-foo"].should == {:method=>:print_foo,:arity=>0}
  end
  
  it "takes an options short name" do
    @cli_opt_user_class.option "prints 'bar'", :short => :b
    define_method_on_opt_user(:print_bar)
    @cli_opt_user_class.valid_options["-b"].should == {:method=>:print_bar,:arity=>0}
    @cli_opt_user_class.valid_options["--print-bar"].should == {:method=>:print_bar,:arity=>0}
  end
  
  it "raises an error when given an invalid option" do
    @cli_opt_user = @cli_opt_user_class.new
    @cli_opt_user.stub!(:argv).and_return(%w{--not-implemented})
    lambda {@cli_opt_user.parse_argv}.should raise_error(CLIOptionParser::InvalidCliOption)
  end
  
  it "only sets CLI options on the first method added after calling option" do
    @cli_opt_user_class.option "does something"
    define_method_on_opt_user(:do_something)
    define_method_on_opt_user(:dont_touch_me)
    Array(@cli_opt_user_class.valid_options).flatten.should_not include(:dont_touch_me)
  end
  
  it "parses ARGV, calling the methods mapping to the options" do
    @cli_opt_user_class.option "prints foo"
    define_method_on_opt_user(:print_foo)
    @cli_opt_user_class.option "prints bar", :short => :b
    define_method_on_opt_user(:print_bar)
    @cli_opt_user_class.option "prints baz"
    define_method_on_opt_user(:print_baz)
    @cli_opt_user = @cli_opt_user_class.new
    @cli_opt_user.stub!(:argv).and_return(%w{-b --print-foo --print-baz})
    @cli_opt_user.parse_argv
    @cli_opt_user.instance_variable_get(:@print_foo).should == "hello from print_foo"
    @cli_opt_user.instance_variable_get(:@print_bar).should == "hello from print_bar"
    @cli_opt_user.instance_variable_get(:@print_baz).should == "hello from print_baz"
  end
  
  it "infers that a option takes an argument from its -arity" do
    @cli_opt_user_class.option "prints ARG", :short => :p
    @cli_opt_user_class.class_eval <<-EVAL
      def print_arg(arg)
        @print_arg = arg
      end
    EVAL
    @cli_opt_user = @cli_opt_user_class.new
    @cli_opt_user.stub!(:argv).and_return(%w{-p printme})
    @cli_opt_user.parse_argv
    @cli_opt_user.instance_variable_get(:@print_arg).should == 'printme'
  end
  
  it "prints a help message" do
    @cli_opt_user_class.option "prints foo"
    define_method_on_opt_user(:print_foo)
    @cli_opt_user_class.option "prints bar", :short => :b
    define_method_on_opt_user(:print_bar)
    @cli_opt_user_class.option "prints baz"
    define_method_on_opt_user(:print_baz)
    @cli_opt_user = @cli_opt_user_class.new
    
    @cli_opt_user.help_message.should match(/\AUsage: #{File.basename($0)} \(options\)/)
    @cli_opt_user.help_message.should match(Regexp.new "    --print-foo, prints foo")
    @cli_opt_user.help_message.should match(Regexp.new "-b, --print-bar, prints bar")
    @cli_opt_user.help_message.should match(Regexp.new "    --print-baz, prints baz")
  end
  
end