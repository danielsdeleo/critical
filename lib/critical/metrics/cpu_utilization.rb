Metric(:cpu_utilization) do

  CPU_USAGE_TYPES = { 2   => 'usr',
                      3   => 'nice',
                      4   => 'sys',
                      5   => 'iowait',
                      6   => 'irq',
                      7   => 'soft',
                      8   => 'steal',
                      9   => 'guest',
                      10  => 'idle'}

  case RUBY_PLATFORM
  when /darwin/
    collects 'ps -eo %cpu'

    reports(:percent_used => :float) do
      result.lines.map(&:to_f).inject(:+)
    end

  when /linux/

    # NOTE: using mpstat for now, which means you need to install the sysstat package.
    # An Alternative is to read from /proc/stat ourselves.
    collects 'mpstat -P ALL 1 1'

    ## mpstat example
    #  mpstat -P ALL 1 1
    #  Linux 2.6.32-21-generic (ubuntu) 	02/27/2011 	_x86_64_	(2 CPU)
    #
    #  04:08:48 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
    #  04:08:49 PM  all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
    #  04:08:49 PM    0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
    #  04:08:49 PM    1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
    #
    #  Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
    #  Average:     all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
    #  Average:       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
    #  Average:       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

    # removes the banner, headings, and 'all' cpu
    reports(:values_by_cpu) do
      @values_by_cpu ||= begin
        lines = result.lines.grep(/Average/)
        lines.slice!(0..1)
        lines.map { |l| l.split }
      end
    end

    reports(:percent_used => :float) do
      values_by_cpu.inject(0.0) { |total, line| total + line[2].to_f + line[4].to_f }
    end

    reports(:by_type) do
      values_by_type = {}
      reported_values = result.lines.grep(/all/).split
      CPU_USAGE_TYPES.each {|index, name| values_by_type[name] = reported_values[index]}
      values_by_type
    end

  else # TODO :(
    raise UnsupportedPlatform, "cpu_utilization does not have an implementation for your platform yet :("
  end

end
