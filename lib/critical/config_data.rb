require 'yajl'

module Critical

  #==Critical::ConfigData
  # ConfigData objects load json and plaintext files recursively from a
  # specified directory. This data can be used in the DSL to dynamically
  # configure Critical to monitor certain metrics, as input for metrics
  # (for example, to configure which ports/processes/disks/etc. to
  # monitor), or whatever other use you think of.
  #
  # Though ConfigData is useful on its own, the primary use case for
  # ConfigData is to integrate with configuration management systems
  # where the alternative would require you to create your Critical
  # configuration files from a template.
  #
  #=== Formats
  # ConfigData supports JSON and plain text file formats. A file is
  # considered to be a JSON file if its filename ends with '.json'. A
  # file is considered to be a plaintext file when the filename does not
  # contain the dot character. Other files are ignored.
  #
  #==== JSON Format Files
  # JSON files are parsed and converted to the corresponding Ruby data
  # structure. Hash keys are converted to symbols. For example, given
  # the following JSON:
  #
  #   {"webservice_ports":[80,443,8080],"roles":["appserver","load_balancer"]}
  #
  # the config data will be:
  #
  #   {:webservice_ports=>[80, 443, 8080], :roles=>["appserver", "load_balancer"]}
  #
  #==== Plain Text Files
  # Plain text files are converted to Arrays of Strings, one item per
  # line of the source file. For example, given the following source
  # file:
  #
  #   appserver
  #   load_balancer
  #   database
  #
  # The corresponding Ruby data structure will be:
  #
  #   ["appserver", "load_balancer", "database"]
  #
  # Plain text files support comments. Any line beginning with zero or
  # more whitespace characters followed by a # character is considered a
  # comment. Trailing comments are not supported. For example, this
  # source text will produce the same result as the previous example:
  #
  #   # This file is generated by Chef.
  #   appserver
  #   load_balancer
  #   database
  #
  #=== Accessing Configuration Data
  # After loading config data files, data can be accessed in a Hash-like
  # manner. The basename of the source file is used as the key. For
  # example, given a source file `/etc/critical/config_data/roles.json`,
  # you would access the data as `config_data['roles']`. ConfigData
  # supports "indifferent access", meaning that symbols (or any object
  # with a usable `to_s` method) can be used to look up the data. So in
  # the 'roles' example, you could access the roles data as
  # `config_data[:roles]`.
  class ConfigData
    include Enumerable

    class PlainTextParser
      COMMENT = /^(?:[\s]*)#/

      def initialize(filename)
        @filename = filename
        @data = []
      end

      def parse
        File.open(@filename, "r") do |f|
          f.each_line do |line|
            @data << line.strip unless line =~ COMMENT
          end
        end
        @data
      end
    end

    REJECT_FOR_PLAINTEXT = /\.(?:[\w]+)/.freeze

    def initialize(*data_dirs)
      @data_dirs = data_dirs.flatten
      @config_data = {}
    end

    def load!
      @data_dirs.each do |data_dir|
        load_json_files_in(data_dir)
        load_plaintext_files_in(data_dir)
      end
    end

    def [](data_item)
      @config_data[data_item.to_s]
    end

    def fetch(data_item, &block)
      @config_data.fetch(data_item, &block)
    end

    def key?(data_item)
      @config.key?(data_item)
    end

    alias :include? :key?
    alias :has_key? :key?
    alias :member? :key?

    def value?(val)
      @config.value?(val)
    end

    alias :has_value? :value?

    def keys
      @config_data.keys
    end

    def length
      @config_data.length
    end

    alias :size :length

    def each(&block)
      @config_data.each(&block)
    end

    private

    def load_json_files_in(data_dir)
      Dir["#{data_dir}/**/*.json"].each do |json_file_name|
        key = File.basename(json_file_name, ".json")
        File.open(json_file_name, "r") do |f|
          parser = Yajl::Parser.new(:symbolize_keys => true)
          @config_data[key] = parser.parse(f)
        end
      end
    end

    def load_plaintext_files_in(data_dir)
      files_to_load = Dir["#{data_dir}/**/*"].reject {|f| f =~ REJECT_FOR_PLAINTEXT}
      files_to_load.each do |filename|
        key = File.basename(filename)
        parser = PlainTextParser.new(filename)
        @config_data[key] = parser.parse
      end
    end
  end
end
