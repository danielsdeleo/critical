module Critical
  module DSL
    module TopLevel
      extend DSL::MetricDSL
      extend Loggable
      extend Hostname
      extend ConfigData
      extend LibraryMetricLoader

      # forwarded to the MonitorCollection instance
      def self.Monitor(*args, &block)
        MonitorCollection.instance.Monitor(*args, &block)
      end
    end
  end
end

