require_metric 'disk_utilization'
require_metric 'memory_utilization'
require_metric 'cpu_utilization'
require_metric 'cluster'

# Monitors use metrics to gather data. They can make judgements about that data
# i.e., the root partition should be less than 90% full, or forward the data to
# external aggregators (not yet implememnted.)
#
# Monitors are also where you define your scheduling.
Monitor(:system) do

  # Monitor statements can be nested, this nesting will be included in the
  # collected data for tracking/tagging purposes.
  Monitor(hostname) do

    # Specify collection intervals with +every+ or +collect_every+
    # The +every+ form takes a block, each monitor you define inside the block
    # will be scheduled to run at that interval.
    every(10=>:seconds) do

      disk_utilization('/') { track :percentage }

      memory_utilization { track :bytes_used }

      cpu_utilization {track :percent_used}

      cluster("critical : worker") do |c|
        c.track :processes
        c.track :total_cpu
        c.track :total_rss
        c.track :uptime
      end

    end
  end
end
