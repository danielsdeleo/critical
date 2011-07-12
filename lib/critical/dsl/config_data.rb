require 'critical/config_data'

module Critical
  module DSL
    module ConfigData
      extend self

      def load_config_data_from(data_dir)
        @config_data = Critical::ConfigData.new(data_dir)
        @config_data.load!
      end

      def config_data
        @config_data
      end
    end
  end
end

