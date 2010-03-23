module Critical
  
  class InvalidCliOption < StandardError
  end

  module Application
    module CLIOptionParser
      module ClassMethods
        def help_banner(banner_text=nil)
          @help_banner = banner_text if banner_text
          @help_banner
        end
      
        def help_footer(footer_text=nil)
          @help_footer = footer_text if footer_text
          @help_footer
        end
      
        def option(desc, opts={})
          @pending_desc, @pending_opts = desc, opts
        end
      
        def descriptions
          @descriptions ||= []
        end
      
        def valid_options
          @valid_options ||= {}
        end
      
        protected
      
        def cli_attr_accessor(attr_name, desc, opts={})
          option(desc, opts)
          attr_writer attr_name
          attr_reader attr_name
        
          # in Ruby 1.9, method visibility will inherit this method's
          # protected-ness
          public attr_name
          public "#{attr_name}=".to_sym
        end
      
        def method_added(method_name)
          if @pending_desc
            help_desc = []
            arity = instance_method(method_name).arity
            help_desc << map_short_option(method_name, arity)
            help_desc << map_long_option(method_name, arity, @pending_opts[:arg])
          
            help_desc << @pending_desc
            descriptions << help_desc
            @pending_desc, @pending_opts = nil, nil
          end
        end
      
        private
      
        def map_long_option(method_name, arity, argstring=nil)
          opt_long_name = '--' + method_name.to_s.gsub('_', '-').gsub(/\=$/, '')
          opt_long_name << " #{argstring.to_s.upcase}" if argstring
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
        attr_accessor :flash_notice
      
        def stdout
          STDOUT
        end

        def stderr
          STDERR
        end

        def argv
          # Avoid accessing ARGV directly to make testing easier
          @argv ||= ARGV.dup
        end
      
        def help_message
          descriptions = self.class.descriptions
          message = help_message_header ? help_message_header + "\n\n" : ""
          message << "Usage: #{File.basename($0)} (options)\n"
        
          long_opts = descriptions.map { |d| d[1] }
          long_opts_length = long_opts.inject(0) { |length, desc| length > desc.length ? length : desc.length  }
        
          descriptions.each do |opt_desc|
            message << format_option_desc(opt_desc, long_opts_length) + "\n"
          end
          message << "\n" + help_footer + "\n" if help_footer
          message
        end
      
        # Parses ARGV and applies all the options
        def parse_opts
          if parse_argv
            apply_options
            true
          end
        end
        
        def parsed_options
          @parsed_options ||= []
        end
      
        def parse_argv
          while opt = argv.shift
            if valid_option?(opt)
              method_to_invoke  = option_to_method(opt)
              method_args       = extract_option_args(opt)
              parsed_options << {:method => method_to_invoke, :args => method_args}
            else
              invalid_option(opt)
              return false
            end
          end
          parsed_options
        end
      
        def apply_option(optname)
          parsed_option_with_args(optname).each do |opt_with_args|
            send(opt_with_args[:method], *opt_with_args[:args])
          end
        end
      
        def apply_options
          while opt_with_args = parsed_options.shift
            send(opt_with_args[:method], *opt_with_args[:args])
          end
        end
      
        private
      
        def parsed_option_with_args(optname)
          opts_with_args = []
          parsed_options.delete_if do |opt_and_args|
            if opt_and_args[:method] == optname || opt_and_args[:method] == "#{optname}=".to_sym
              opts_with_args << opt_and_args
            end
          end
          opts_with_args
        end
        
        def help_message_header
          flash_notice || help_banner
        end
      
        def help_banner
          self.class.help_banner
        end
      
        def help_footer
          self.class.help_footer
        end
      
        def format_option_desc(opt_desc, long_opts_length)
          line = ""
          line << (opt_desc[0] ? opt_desc[0] + ", " : "").rjust(5)
          line << opt_desc[1].ljust(long_opts_length + 2)
          line << opt_desc[2]
        end
      
        def valid_options
          self.class.valid_options
        end
        
        def valid_option?(opt)
          !!valid_options[opt]
        end
      
        def option_to_method(opt)
          valid_options[opt][:method]
        end
      
        def extract_option_args(opt)
          number_of_args = valid_options[opt][:arity]
          argv.slice!(0...number_of_args)
        end
      
        def invalid_option(opt)
          self.flash_notice = "Invalid option: #{opt}"
        end

      end
    
    end
  end
end
