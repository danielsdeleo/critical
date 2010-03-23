require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module TestHarness
  class CLIOptUser
    extend  Application::CLIOptionParser::ClassMethods
    include Application::CLIOptionParser::InstanceMethods
    
  end
end

describe Application::CLIOptionParser do
  before do
    @cli_opt_user_class = Class.new(TestHarness::CLIOptUser)
  end
  
  def define_method_on_opt_user(method_name)
    @cli_opt_user_class.class_eval <<-EVAL
      def #{method_name}
        @#{method_name} = "hello from #{method_name}"
      end
      
      def #{method_name.to_s.sub(/^print_/, '')}
        @#{method_name}
      end
    EVAL
  end
  
  it "sets an option's description" do
    @cli_opt_user_class.option "prints 'foo' to the screen"
    define_method_on_opt_user(:print_foo)
    @cli_opt_user_class.valid_options["--print-foo"].should == {:method=>:print_foo,:arity=>0}
  end
  
  it "sets an option's short name" do
    @cli_opt_user_class.option "prints 'bar'", :short => :b
    define_method_on_opt_user(:print_bar)
    @cli_opt_user_class.valid_options["-b"].should == {:method=>:print_bar,:arity=>0}
    @cli_opt_user_class.valid_options["--print-bar"].should == {:method=>:print_bar,:arity=>0}
  end
  
  it "only sets CLI options on the first method added after calling option" do
    @cli_opt_user_class.option "does something"
    define_method_on_opt_user(:do_something)
    define_method_on_opt_user(:dont_touch_me)
    Array(@cli_opt_user_class.valid_options).flatten.should_not include(:dont_touch_me)
  end

  describe "parsing options" do
    before do
      @cli_opt_user = @cli_opt_user_class.new
    end
    
    it "doesn't return a false-y value if no options are given" do
      @cli_opt_user.stub!(:argv).and_return([])
      return_val = @cli_opt_user.parse_argv
      return_val.should_not be_nil
      return_val.should_not be_false
    end
    
    it "parses the options into a hash" do
      @cli_opt_user_class.option "prints 'bar'", :short => :b
      define_method_on_opt_user(:print_bar)
      @cli_opt_user_class.option "sets the value of 'foo'", :short => :f
      @cli_opt_user_class.class_eval do
        attr_writer :foo
        attr_reader :foo
      end
      @cli_opt_user.stub!(:argv).and_return(%w{-b -f baz})
      @cli_opt_user.parse_argv
      @cli_opt_user.parsed_options.should == [{:args=>[], :method=>:print_bar}, {:args=>["baz"], :method=>:foo=}]
    end

    it "allows for options that are specified multiple times" do
      @cli_opt_user_class.option "append to array", :short => :a
      @cli_opt_user_class.class_eval do
        def append(arg)
          @array ||= []
          @array << arg
        end
        attr_reader :array
      end
      
      @cli_opt_user.stub!(:argv).and_return(%w{-a foo -a bar -a baz})
      @cli_opt_user.parse_argv
      @cli_opt_user.apply_option(:append)
      @cli_opt_user.array.should == %w[foo bar baz]
    end

    it "has a flash_notice string for adding a notice to the help banner" do
      @cli_opt_user.flash_notice = "Invalid option: --wack-opt"
      @cli_opt_user.flash_notice.should == "Invalid option: --wack-opt"
    end

    it "does sets flash_notice to 'Invalid option: $optname' and returns false when given an invalid option" do
      @cli_opt_user.stub!(:argv).and_return(%w{--not-implemented})
      @cli_opt_user.parse_argv
      @cli_opt_user.flash_notice.should == "Invalid option: --not-implemented"
    end

    it "infers that a option takes an argument from its -arity" do
      @cli_opt_user_class.option "prints ARG", :short => :p
      @cli_opt_user_class.class_eval <<-EVAL
        def print_arg(arg)
          @print_arg = arg
        end
      EVAL
      
      @cli_opt_user.stub!(:argv).and_return(%w{-p printme})
      @cli_opt_user.parse_opts
      @cli_opt_user.instance_variable_get(:@print_arg).should == 'printme'
    end

    it "creates an option for an attribute writer" do
      @cli_opt_user_class.option "set the value of ivar_from_cli", :short => :i
      @cli_opt_user_class.class_eval do
        attr_writer :ivar_from_cli
        attr_reader :ivar_from_cli
      end
      
      @cli_opt_user.stub!(:argv).and_return(%w{-i setfromcli})
      @cli_opt_user.parse_opts
      @cli_opt_user.ivar_from_cli.should == "setfromcli"
    end

    it "creates an option for an attribute accessor" do
      @cli_opt_user_class.class_eval do
        cli_attr_accessor :ivar_from_cli, "set the value of ivar_from_cli", :short => :i
      end
      
      @cli_opt_user.stub!(:argv).and_return(%w{-i setfromcli})
      @cli_opt_user.parse_opts
      @cli_opt_user.ivar_from_cli.should == "setfromcli"
    end

    it "specifies a string to use in the ARG field of the help message" do
      @cli_opt_user_class.option "specifies the pidfile", :short => :p, :arg => :pidfile
      @cli_opt_user_class.class_eval do
        attr_writer :pidfile
        attr_reader :pidfile
      end
      
      @cli_opt_user.help_message.should match(Regexp.new "-p, --pidfile PIDFILE  specifies the pidfile")
    end
    
    describe "when options have been defined" do
      before do
        @cli_opt_user_class.option "prints foo"
        define_method_on_opt_user(:print_foo)
        @cli_opt_user_class.option "prints bar", :short => :b
        define_method_on_opt_user(:print_bar)
        @cli_opt_user_class.option "prints baz"
        define_method_on_opt_user(:print_baz)
      end
      
      it "parses ARGV, calling the methods mapping to the options" do
        @cli_opt_user.stub!(:argv).and_return(%w{-b --print-foo --print-baz})
        @cli_opt_user.parse_opts
        @cli_opt_user.foo.should == "hello from print_foo"
        @cli_opt_user.bar.should == "hello from print_bar"
        @cli_opt_user.baz.should == "hello from print_baz"
      end

      it "applies options individually" do
        @cli_opt_user.stub!(:argv).and_return(%w{-b --print-foo baz})
        @cli_opt_user.parse_argv
        @cli_opt_user.apply_option(:print_foo)
        @cli_opt_user.foo.should == "hello from print_foo"
        @cli_opt_user.apply_option(:print_bar)
        @cli_opt_user.bar.should == "hello from print_bar"
      end

      it "removes previously applied options from the set of parsed options" do
        @cli_opt_user.stub!(:argv).and_return(%w{-b})
        @cli_opt_user.parse_argv
        @cli_opt_user.apply_option(:print_bar)
        @cli_opt_user.parsed_options.should == []
      end

      it "applies all un-applied options at once" do
        @cli_opt_user.stub!(:argv).and_return(%w{-b --print-foo --print-baz})
        @cli_opt_user.parse_argv
        @cli_opt_user.apply_option(:print_bar)

        @cli_opt_user.should_not_receive(:print_bar)

        @cli_opt_user.apply_options
        @cli_opt_user.foo.should == "hello from print_foo"
        @cli_opt_user.bar.should == "hello from print_bar"
        @cli_opt_user.baz.should == "hello from print_baz"
      end
      
      it "doesn't return a false-y value if no options are given" do
        @cli_opt_user.stub!(:argv).and_return([])
        returned_val = @cli_opt_user.parse_opts
        returned_val.should_not be_nil
        returned_val.should_not be_false
      end

      it "prints a help message" do
        @cli_opt_user.help_message.should match(/\AUsage: #{File.basename($0)} \(options\)/)
        @cli_opt_user.help_message.should match(Regexp.new "    --print-foo  prints foo")
        @cli_opt_user.help_message.should match(Regexp.new "-b, --print-bar  prints bar")
        @cli_opt_user.help_message.should match(Regexp.new "    --print-baz  prints baz")
      end

      it "includes the flash_notice when printing the help message" do
        @cli_opt_user.flash_notice = "You did something dumb."
        @cli_opt_user.help_message.should match /You did something dumb\./
      end

    end
  end
end