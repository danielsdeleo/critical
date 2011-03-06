require 'pp'

module Critical
  module OutputHandler
    class Text < Base
      attr_reader :io, :warnings
      def initialize(opts={})
        @io = opts[:output] || STDOUT
        @warnings = []
      end

      def collection_started
        io.puts "collecting #{metric.to_s}"
      end

      def collection_failed(*args)
        io.puts "Collection of #{metric.to_s} FAILED"
        print_annotations
        print_exception(*args)
      end

      def processing_failed(*args)
        io.puts "Processing of #{metric.to_s} FAILED"
        print_annotations
        print_exception(*args)
      end

      def expectation_failed(*args)
        io.puts "Expectation on #{metric.to_s} FAILED"
        print_annotations
        print_exception(*args)
      end

      def expectation_succeeded(*args)
        io.puts "Expectation on #{metric.to_s} succeeded"
        success_data = normalize_exception(*args)
        io.puts success_data[:name] + ": " + success_data[:message]
      end

      def annotate(*args)
        warnings << normalize_exception(*args)
      end

      private

      def print_annotations
        warnings.each do |warning|
          io.puts "Received warning prior to failure: "
          io.puts warning[:name] + ": " + warning[:message]
          PP.pp(warning[:stacktrace], io)
        end
      end

      def print_exception(*args)
        exception_data = normalize_exception(*args)
        io.puts exception_data[:name] + ": " + exception_data[:message]
        PP.pp(exception_data[:stacktrace], io)
      end

    end
  end
end
