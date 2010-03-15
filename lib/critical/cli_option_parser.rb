module Critical
  module CLIOptionParser
    class InvalidCliOption < StandardError
    end
    
    module ClassMethods
      def help_banner(banner_text=nil)
        @help_banner = banner_text if banner_text
        @help_banner
      end
      
      def help_footer(footer_text=nil)
        @help_footer = footer_text if footer_text
        @help_footer
      end
      
      # option("prints help and exits", :required => true)
      def option(desc, opts={})
        @pending_desc, @pending_opts = desc, opts
      end
      
      def method_added(method_name)
        if @pending_desc
          help_desc = []
          arity = instance_method(method_name).arity
          help_desc << map_short_option(method_name, arity)
          help_desc << map_long_option(method_name, arity)
          help_desc << @pending_desc
          descriptions << help_desc
          @pending_desc, @pending_opts = nil, nil
        end
      end
      
      def descriptions
        @descriptions ||= []
      end
      
      def valid_options
        @valid_options ||= {}
      end
      
      private
      
      def map_long_option(method_name, arity)
        opt_long_name = '--' + method_name.to_s.gsub('_', '-')
        valid_options[opt_long_name] = {:method=>method_name,:arity=>arity}
        opt_long_name
      end
      
      def map_short_option(method_name, arity)
        if short = @pending_opts[:short]
          short = short.to_s
          short = '-' + short unless short[/^\-/]
          valid_options[short] = {:method=>method_name,:arity=>arity}
          short
        else
          nil
        end
      end
      
    end
    
    module InstanceMethods
      
      def stdout
        STDOUT
      end

      def stderr
        STDERR
      end

      # Avoid accessing ARGV directly to make testing easier
      def argv
        @argv ||= ARGV.dup
      end
      
      def help_message
        descriptions = self.class.descriptions
        message = help_banner ? help_banner + "\n\n" : ""
        message << "Usage: #{File.basename($0)} (options)\n"
        
        long_opts = descriptions.map { |d| d[1] }
        long_opts_length = long_opts.inject(0) { |length, desc| length > desc.length ? length : desc.length  }
        
        descriptions.each do |opt_desc|
          message << format_option_desc(opt_desc, long_opts_length) + "\n"
        end
        message << "\n" + help_footer + "\n" if help_footer
        message
      end
      
      def parse_argv
        while opt = argv.shift
          assert_valid_option!(opt)
          method_to_invoke  = option_to_method(opt)
          method_args       = extract_option_args(opt)
          send(method_to_invoke, *method_args)
        end
      end
      
      private
      
      def help_banner
        self.class.help_banner
      end
      
      def help_footer
        self.class.help_footer
      end
      
      def format_option_desc(opt_desc, long_opts_length)
        line = ""
        line << (opt_desc[0] ? opt_desc[0] + ", " : "").rjust(5)
        line << opt_desc[1].ljust(long_opts_length) + ", "
        line << opt_desc[2]
      end
      
      def valid_options
        self.class.valid_options
      end
      
      def assert_valid_option!(opt)
        valid_options[opt] || invalid_option(opt)
      end
      
      def option_to_method(opt)
        valid_options[opt][:method]
      end
      
      def extract_option_args(opt)
        number_of_args = valid_options[opt][:arity]
        argv.slice!(0...number_of_args)
      end
      
      def invalid_option(option)
        raise InvalidCliOption, "I don't respond to the the '#{option}' option. Better luck next time :("
      end

    end
    
  end
end