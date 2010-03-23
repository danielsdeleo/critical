require 'singleton'

module Critical
  
  # Yields the instance of Critical::Application::Configuration so you can
  # configure it in a block, like
  #   Critical.configure do |c|
  #     c.metric_directory("/etc/critical/metrics")
  #   end
  def self.configure
    yield Application::Configuration.instance
  end
  
  # Returns the instance of Critical::Application::Configuration
  def self.config
    Application::Configuration.instance
  end
  
  module Application
    class Configuration
      include Loggable
      extend  Loggable
      include Singleton
      extend CLIOptionParser::ClassMethods
      include CLIOptionParser::InstanceMethods
      
      help_banner "Critical: Not even 0.0.1 yet."
      help_footer "http://github.com/danielsdeleo/critical"
      
      def self.configure!
        self.instance.configure
      end
      
      attr_reader :source_files
      
      def initialize
        reset!
      end
      
      def reset!
        @source_files   = []
        @daemonize      = nil
        @eval_line_no   = nil
      end
      
      def configure
        help unless parse_opts
      end
      
      option "Print the version and exit", :short => :v
      def version
        stdout.puts help_banner
        exit 2
      end
      
      option "Print this message and exit", :short => :h
      def help
        stdout.puts help_message
        exit 1
      end
      
      option "Load the given source file or directory", :short => :r, :arg => "[directory|file]"
      def require(file_or_dir)
        @source_files << File.expand_path(file_or_dir)
      end
      
      cli_attr_accessor :pidfile, "The file where the process id is stored", :short => :p
      
      option "Detach and run as a daemon", :short => :D
      def daemonize
        @daemonize = true
      end
      
      def daemonize?
        @daemonize || false
      end
      
      option "A sting of ruby code to evaluate", :short => :e, :arg => :code
      def eval(ruby_code)
        @eval_line_no ||= 0
        @eval_line_no += 1
        Kernel.eval(ruby_code, TOPLEVEL_BINDING, "-e command line option", @eval_line_no)
      end
      
    end
  end
end