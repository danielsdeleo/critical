Metric(:freemem) do
  collects "vm_stat"
  
  vm_stat_format = /^Pages free:[\s]+([\d]+)\.$/
  
  reports(:pages_free => :integer) do
    result.line(1).fields(vm_stat_format).field(0)
  end
  
  reports(:bytes_free => :integer) do
    pages_free * 4096.0
  end
  
  reports(:kb_free => :integer) do
    pages_free * 4
  end
  
  reports(:mb_free => :float) do
    kb_free / 1024.0
  end
end

Monitor(:memory) do
  
  freemem do
    #record memory.mb_free #or some such API...
    critical { mb_free.should be > 1512}
  end
  
end
