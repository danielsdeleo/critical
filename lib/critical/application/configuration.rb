require 'singleton'

module Critical
  module Application
    class Configuration
      include Singleton
      extend CLIOptionParser::ClassMethods
      include CLIOptionParser::InstanceMethods
      
      help_banner "Critical: Not even 0.0.1 yet."
      help_footer "http://github.com/danielsdeleo/critical"
      def self.configure!
        self.instance.parse_argv
      end
      
      def self.method_missing(method_name, *args, &block)
        if instance.respond_to?(method_name)
          instance.send(method_name, *args, &block)
        else
          super
        end
      end
      
      
      attr_reader :metric_files
      
      def initialize
        reset!
      end
      
      def reset!
        @metric_files = []
      end
      
      option "Print the version and exit", :short => :v
      def version(*args)
        stdout.puts help_banner
        exit 1
      end
      
      option "Print a not-that-helpful message and exit", :short => :h
      def help
        stdout.puts help_message
        exit 1
      end
      
      option "Load metric definitions from the given directory", :short => :m
      def metric_directory(dir)
        @metric_files += Dir[File.expand_path(dir) + "/**/*.rb"]
      end
      
    end
  end
  
  
  def configure
    yield Application::Configuration.instance
  end
  
  def configuration
    Application::Configuration.instance
  end
  
end