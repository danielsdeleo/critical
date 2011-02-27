require 'socket'

module Critical
  module Trending
    class GraphiteHandler

      def initialize
        
      end

      class Connection
        include Loggable

        attr_reader :host
        attr_reader :port

        def initialize(host, port, socket_class=TCPSocket)
          @host, @port = host, port
          @socket_class = socket_class
          @conection = nil
        end

        def socket
          @connection ||= begin
            log.debug { "Setting up connection to graphite/carbon at #{host}:#{port}" }
            @socket_class.new(host, port)
          end
        rescue Errno::ECONNREFUSED
          log.error { "Connection to graphite/carbon refused for #{host}:#{port}. Is carbon running and listening on this port?"}
        rescue Errno::ETIMEDOUT
          log.error { "Timed out attempting to connect to graphite/carbon at #{host}:#{port}. The host might be down or this port could be firewalled."}
        rescue SocketError => e
          log.error { "Error connecting to graphite/carbon at #{host}:#{port} - #{e.message}" }
          if e.message =~ /getaddrinfo/
            log.error { "Check that the hostname is correct and is resolvable from here." }
          end
        end

        def write(key, value, options={})
          if namespace = options.delete(:namespace)
            key = [namespace.join('.'), key].join('.')
          end
          socket.write("#{key} #{value} #{timestamp}\n")
          socket.flush
        end

        def timestamp
          Time.new.utc.to_i
        end

      end
    end
  end
end