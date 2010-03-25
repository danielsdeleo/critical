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
        # Parse the options, bail out if they're malformed
        help unless parse_argv
        # set the log level as early as possible
        apply_option :log_level
        # Apply the config file setting, read the config, then apply CLI opts
        # so cli opts can take precedence over config file settings
        apply_option :config_file
        read_config_file
        apply_options
        # Run a sanity check on the config
        validate_configuration
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
      
      option "The configuration file to use", :short => :c
      def config_file=(config_file)
        @config_file = File.expand_path(config_file)
      end
      attr_reader :config_file
      
      option "Set the verbosity of critical's error log", :short => :l, :arg => "[debug|info|warn|error|fatal]"
      def log_level=(verbosity)
        pp :log_level_set => verbosity
        Loggable::Logger.instance.level = verbosity.downcase
      end
      attr_reader :log_level
      
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
      
      # Yields a block to OutputHandler::Dispatcher.configure
      def reporting(&block)
        OutputHandler::Dispatcher.configure(&block)
      end
      
      # Returns the Loggable::Formatters::Ruby class so you can configure the fields it includes
      def log_format
        Loggable::Formatters::Ruby
      end
      
      def read_config_file
        if config_file && File.file?(config_file)
          log.debug { "Loading configuration file #{config_file}" }
          Kernel.load config_file
        elsif config_file
          reason = File.exist?(config_file) ? "isn't a file" : "doesn't exist"
          self.flash_notice = "The configuration file you specified: #{config_file} #{reason}"
          help
        else
          log.debug { "No config file specified." }
        end
      end
      
      private
      
      def validate_configuration
        if @source_files.empty?
          invalid_config "No source files loaded, nothing to monitor."
        elsif MonitorCollection.instance.empty?
          invalid_config "Source files contain no monitors, nothing to do."
        end
      end
      
      def invalid_config(message)
        self.flash_notice = message
        help
      end
      
    end
  end
end