Metric(:freemem) do |freemem|
  freemem.collects "vm_stat"
  
  vm_stat_format = /^Pages free:[\s]+([\d]+)\.$/
  
  freemem.reports(:pages_free => :integer) do
    result.line(1).fields(vm_stat_format).field(0)
  end
  
  freemem.reports(:bytes_free => :integer) do
    pages_free * 4096.0
  end
  
  freemem.reports(:kb_free => :integer) do
    pages_free * 4
  end
  
  freemem.reports(:mb_free => :float) do
    kb_free / 1024.0
  end
end

Monitor(:memory) do
  
  freemem do |memory|
    #record memory.mb_free #or some such API...
    memory.mb_free.is gte(1512)
  end
  
end
