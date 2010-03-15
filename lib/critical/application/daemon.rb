module Critical
  module Application
    module Daemon
      extend self
      
      def daemonize!(opts={})
        process_opts!(opts)
        
        detach
        save_and_lock_pid(opts[:pidfile])
        close_descriptors
      end

      private
      
      def process_opts!(opts)
        opts[:pidfile]  ||= "/tmp/critical.pid"
      end

      def close_descriptors
        raise "TODO"
        # can close, or reopen w/ dev/null, or reopen w/ a log file...
        stdin.close
        stdout.close
        stderr.close
      end

      def detach
        delayed_exit if fork
        Process.setsid
        delayed_exit if fork
      end

      def save_and_lock_pid(pidfile)
        if File.new(pidfile).flock(File::LOCK_EX | File::LOCK_NB)
          File.open(pidfile, "w", 0644) {|f| f.puts Process.pid }
        else
          raise "Can't run, another process has the lock on the pidfile #{pidfile}"
        end
      end

      # Wait a short time, then exit. The reason for this is if you run the app
      # via ssh run_application there can be a race between exiting and setsid.
      # If you lose this race the OS will kill you before init can adopt you.
      # It is rare that this happens, but no harm in being paranoid about it.
      def delayed_exit
        sleep 0.1
        exit
      end
      
      def stdin
        STDIN
      end
      
      def stderr
        STDERR
      end

      def stdout
        STDOUT
      end
      
    end
  end
end