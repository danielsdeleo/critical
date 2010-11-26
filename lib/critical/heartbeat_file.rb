require 'tmpdir'

module Critical
  # A temporary file used for heartbeating between master and child process.
  # Uses the same design as unicorn: fchmod(2)s an unlinked temporary file
  # to update the file's ctime. 
  class HeartbeatFile < ::File

    def self.new
      f = super(random_path, File::RDWR|File::CREAT|File::EXCL, 0600)
      unlink(f.path)
      f
    rescue Errno::EEXIST
      retry
    end

    def self.random_path
      "#{Dir.tmpdir}/critical-heartbeat-file-#{rand(1048576)}"
    end

    attr_reader :alternator

    def initialize(*args)
      super(*args)
      @alternator = 0
    end

    def alive!
      @alternator = 1 - @alternator
      chmod(@alternator)
    end

    def time_since_heartbeat
      (Time.now - stat.ctime).floor
    end

  end
end