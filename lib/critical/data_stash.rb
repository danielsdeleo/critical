module Critical
  module DataStashDSL

    def stash(name=nil)
      create_stash_dir
      name ||= safe_str
      DataStash.new("/tmp/critical/stash/#{name}")
    end

    # Ensures that the stash directory exists.
    #--
    # TODO: stash directory should be configurable,
    # and should not be created here. Instead it should be
    # created by an installation process so it can live inside an
    # otherwise unwritable directory (e.g., /var/cache/critical)
    def create_stash_dir
      Dir.mkdir('/tmp/critical', 0700) unless File.directory?('/tmp/critical')
      Dir.mkdir('/tmp/critical/stash', 0700) unless File.directory?('/tmp/critical/stash')
    end
  end

  class DataStash

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def save(data)
      File.open(@path, File::CREAT|File::TRUNC|File::RDWR, 0600) do |f|
        f.flock(File::LOCK_EX)
        f.puts(Marshal.dump({:hack => data}))
        f.fsync
      end
    end

    def load
      File.open(@path, File::RDONLY) do |f|
        f.flock(File::LOCK_SH)
        Marshal.load(f.read)[:hack]
      end
    end

  end
end
