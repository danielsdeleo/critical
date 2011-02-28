require_metric 'disk_utilization'

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

      # # You can also use a block variable with Monitor if you prefer that style:
      # Monitor(:disk_utilization) do |disks|
      # 
      #   # Monitors are defined in terms of the metrics they use. In this case,
      #   # we use the df() metric defined above. This metric is 
      #   # /unix_box/disks/df(/) in the namespace.
      #   #
      #   # If you hadn't passed a block variable to +Monitor+ above, you could
      #   # just write <tt>df("/")</tt> instead of <tt>disks.df("/")</tt>
      #   disks.df("/") do |root_partition|
      #     # root_partition.warning  { percentage <= 40 }
      #     # implemented:
      #     #root_partition.critical { percentage <= 35 }
      #     root_partition.track :percentage
      #     ###root_partition.percentage.trend("root partition", opts={})
      #   end
      # end
    end
  end
end