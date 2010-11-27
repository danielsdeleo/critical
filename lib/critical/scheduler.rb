require 'thread'

module Critical
  class Scheduler
    class Task

      attr_reader :next_run

      attr_reader :interval

      attr_reader :block

      attr_reader :monitor
      
      def initialize(qualified_monitor_name, interval, next_run=nil)
        @monitor, @interval =  qualified_monitor_name, interval
        @next_run = next_run || Time.new.to_i
      end
      
      # Reschedules this task for the next time it should run
      def succ!
        @next_run += @interval
      end
    end
    
    include Loggable
    include Enumerable

    def self.quantum
      5
    end

    attr_reader :tasks

    def initialize(*schedule_tasks)
      @tasks = Hash.new { |hsh, key| hsh[key] = [] }
      schedule_tasks.flatten.each { |t| schedule(t) }
    end

    def schedule(task)
      @tasks[quantize(task.next_run)] << task
    end

    def time_until_next_task
      time_to_sleep = next_run - current_time
      time_to_sleep = 0 if time_to_sleep < 0
      time_to_sleep
    end

    # Yields each monitor currently scheduled to be exeuted
    def each
      buckets = task_buckets_to_run.map { |bucket| tasks.delete(bucket) }.compact
      buckets.each do |tasks_in_bucket|
        tasks_in_bucket.each do |task|
          yield task.monitor
          reschedule_task(task)
        end
      end
    end

    def next_run
      @tasks.keys.sort.first
    end

    private

    def task_buckets_to_run
      now = current_time
      @tasks.keys.select { |t| t <= now }.sort
    end

    def reschedule_task(task)
      task.succ!
      schedule task
    end

    def quantum
      self.class.quantum
    end

    def quantize(int)
      int - (int % quantum)
    end

    def current_time
      Time.new.to_i
    end
  end

end
