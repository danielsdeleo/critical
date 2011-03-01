Metric(:cluster) do

  monitors :process_name

  collects "ps -e -o %cpu -o rss -o vsz -o etime -o args"

  ## Example Data:
  # 0.0 14480  43436    01:56:49 critical : worker[1]                                               
  # 0.0 14488  43436    01:56:49 critical : worker[2]                                               
  # 0.0 14556  43520    01:56:49 critical : worker[3]                                               
  reports(:matching_processes) do
    pattern = process_name.kind_of?(Regexp) ? pattern : /#{Regexp.escape(process_name)}/
    result.lines.grep(pattern).map { |l| l.split }
  end

  reports(:processes => :int) do
    matching_processes.size
  end

  reports(:total_cpu => :float) do
    matching_processes.map { |proc_data| proc_data[0].to_f }.inject(:+)
  end

  # converted to bytes so the units are nice in the graphs.
  reports(:total_rss => :int) do
    matching_processes.map { |proc_data| proc_data[1].to_i * 1024  }.inject(:+)
  end

  # Formats are:
  # * 1-10:14:05
  # * 21:11:54
  # * 00:02
  def etime_to_i(etime)
    days, hours, minutes, seconds = case etime
    when /([\d]+)-([\d]{2}):([\d]{2}):([\d]{2})/
      [$1.to_i, $2.to_i, $3.to_i, $4.to_i]
    when /([\d]{2}):([\d]{2}):([\d]{2})/
      [0, $1.to_i, $2.to_i, $3.to_i]
    when /([\d]{2}):([\d]{2})/
      [0, 0, $1.to_i, $2.to_i]
    end
    (days * 86400) + (hours * 3600) + (minutes * 60) + seconds
  end

  # The uptime of the longest-lived process in the group
  reports(:uptime => :int) do
    matching_processes.map { |proc_data| etime_to_i(proc_data[3])  }.max
  end

end