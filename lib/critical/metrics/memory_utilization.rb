Metric(:memory_utilization) do
  case RUBY_PLATFORM
  when /darwin/
    collects "vm_stat"

    pagesize = `sysctl -n hw.pagesize`.strip.to_i
    total_memory_in_bytes = `sysctl -n hw.memsize`.strip.to_i

    vm_stat_format = /^Pages free:[\s]+([\d]+)\.$/
  
    reports(:pages_free => :integer) do
      result.line(1).fields(vm_stat_format).field(0)
    end
  
    reports(:bytes_free => :integer) do
      pages_free * pagesize
    end

    reports(:bytes_used => :integer) do
      total_memory_in_bytes - bytes_free
    end

  when /linux/

    ## Example:
    #              total       used       free     shared    buffers     cached
    # Mem:       2058028    1489388     568640          0     139352     865092
    # -/+ buffers/cache:     484944    1573084
    # Swap:       916472          0     916472

    collects 'free -b'

    reports(:total_memory_in_kb => :int) do
      result.line(1).split[1]
    end

    reports(:bytes_used => :int) do
      result.line(2).split[2]
    end

  else
    raise UnsupportedPlatform, "memory_utilization does not have an implementation for your platform yet :("
  end

  reports(:kb_free => :integer) do
    bytes_free / 1024
  end

  reports(:kb_used => :integer) do
    pp :kb_used => (bytes_used / 1024)
    bytes_used / 1024
  end

  reports(:mb_free => :float) do
    kb_free / 1024.0
  end

  reports(:mb_used => :float) do
    kb_used.to_f / 4.0
  end

end
