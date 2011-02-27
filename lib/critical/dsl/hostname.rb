module Critical
  module DSL
    # Used to make the hostname available for namespaces without shelling out
    # every single time
    module Hostname
      extend self

      HOSTNAME = `hostname -s`.strip!

      def hostname
        HOSTNAME
      end
    end
  end
end