require 'critical/loggable'

module Critical
  # == Critical::Protocol
  # The protocol used to distribute tasks to the workers. Very basic text-based
  # protocol currently. Likely to change a lot in the near future or be replaced
  # entirely with a different protocol.
  module Protocol
    class Client

      include Loggable

      class DequeuedTask < Struct.new(:client, :msg, :url)

        alias :message :msg

        def ack
          client.ack
        end

      end

      def initialize(io)
        @io = io
      end

      def publish_task(task_url)
        @io.puts(task_url)
        @io.puts(".")
        response = String.new
        @io.read_nonblock(16384, response)
        #handle_response # TODO: deal with rejection
      rescue Errno::EAGAIN
        IO.select([@io], nil, nil, 1)
        retry
      rescue Errno::EPIPE
        # consider it a rejection.
      rescue EOFError
      ensure
        @io.close
      end

      def accept_task
        msg = String.new
        if @io.read_nonblock(16384, msg)
          if dequeued_task = parse(msg)
            yield dequeued_task
          else
            reject
          end
        else
          # bogus connection -- no data. skip it.
          log.debug { "connection #{reader.inspect} had no data, skipping it." }
        end
        true
      ensure
        @io.close unless @io.closed?
      end


      def parse(msg)
        if msg =~ /^\.\Z/
          DequeuedTask.new(self, msg, msg[/\A.+$/])
        else
          false
        end
      end

      def reject
        @io.puts("REJECTED\nBad Format\n.\n")
        @io.close
      end

      def ack
        @io.puts("ACK\n.\n")
        @io.close
      end

    end
  end
end